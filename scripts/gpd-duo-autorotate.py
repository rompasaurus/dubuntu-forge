#!/usr/bin/env python3
"""GPD Duo autorotate daemon.

Monitors iio-sensor-proxy over D-Bus and rotates the built-in display
using Mutter's DisplayConfig API. Works on GNOME/Wayland without needing
SW_TABLET_MODE or any shell extension.
"""

import subprocess
import sys

try:
    import dbus
    from dbus.mainloop.glib import DBusGMainLoop
    from gi.repository import GLib
except ImportError:
    print("Missing dependencies. Install with:")
    print("  sudo apt-get install python3-dbus python3-gi gir1.2-glib-2.0")
    sys.exit(1)

# Mutter transform values
TRANSFORM_NORMAL = 0
TRANSFORM_90 = 1      # rotated left (counter-clockwise)
TRANSFORM_180 = 2
TRANSFORM_270 = 3     # rotated right (clockwise)

# Map sensor proxy orientation to Mutter transform.
# GPD Duo has a portrait panel used in landscape, so the accelerometer
# reports "left" in normal laptop orientation due to the mount matrix.
# The custom gpd-sensor-proxy uses short names (left/right), while
# iio-sensor-proxy uses long names (left-up/right-up).
ORIENTATION_MAP = {
    "normal":    TRANSFORM_90,
    "left-up":   TRANSFORM_NORMAL,
    "left":      TRANSFORM_NORMAL,
    "right-up":  TRANSFORM_180,
    "right":     TRANSFORM_180,
    "bottom-up": TRANSFORM_270,
}

current_transform = None


def get_display_config(session_bus):
    """Get current display state from Mutter."""
    proxy = session_bus.get_object(
        "org.gnome.Mutter.DisplayConfig",
        "/org/gnome/Mutter/DisplayConfig",
    )
    iface = dbus.Interface(proxy, "org.gnome.Mutter.DisplayConfig")
    return iface.GetCurrentState()


def apply_rotation(session_bus, transform):
    """Apply a rotation transform to the built-in display via Mutter D-Bus."""
    global current_transform
    if transform == current_transform:
        return

    state = get_display_config(session_bus)
    serial = state[0]
    monitors = state[1]
    logical_monitors = state[2]

    # Find the built-in monitor
    builtin_connector = None
    builtin_mode = None
    for monitor in monitors:
        monitor_spec = monitor[0]  # (connector, vendor, product, serial)
        modes = monitor[1]
        props = monitor[2]
        if props.get("is-builtin", False):
            builtin_connector = monitor_spec
            # Find the current/preferred mode
            for mode in modes:
                mode_props = mode[6] if len(mode) > 6 else {}
                if mode_props.get("is-current", False):
                    builtin_mode = mode[0]  # mode id string
                    break
            if not builtin_mode:
                for mode in modes:
                    mode_props = mode[6] if len(mode) > 6 else {}
                    if mode_props.get("is-preferred", False):
                        builtin_mode = mode[0]
                        break
            break

    if not builtin_connector or not builtin_mode:
        print("ERROR: Could not find built-in display")
        return

    # Build the logical monitors config
    new_logical_monitors = []
    for lm in logical_monitors:
        lm_x, lm_y, lm_scale, lm_transform, lm_primary, lm_monitors = (
            lm[0], lm[1], lm[2], lm[3], lm[4], lm[5],
        )
        # Check if this logical monitor contains the built-in display
        has_builtin = False
        for mon in lm_monitors:
            if mon[0] == builtin_connector[0]:  # connector name
                has_builtin = True
                break

        if has_builtin:
            # Apply new transform to built-in display
            # ApplyMonitorsConfig monitor tuple is (connector, mode_id, properties)
            new_monitors = dbus.Array([
                dbus.Struct((
                    dbus.String(builtin_connector[0]),  # connector
                    dbus.String(builtin_mode),           # mode id
                    dbus.Dictionary({}, signature="sv"),
                ), signature=None)
            ], signature="(ssa{sv})")
            new_logical_monitors.append(
                dbus.Struct((
                    dbus.Int32(lm_x),
                    dbus.Int32(lm_y),
                    dbus.Double(lm_scale),
                    dbus.UInt32(transform),
                    dbus.Boolean(lm_primary),
                    new_monitors,
                ), signature=None)
            )
        else:
            # Keep other monitors unchanged
            other_monitors = dbus.Array([], signature="(ssa{sv})")
            for mon in lm_monitors:
                # Find current mode for this monitor
                mon_mode = ""
                for m in monitors:
                    if m[0][0] == mon[0]:
                        for mode in m[1]:
                            mode_props = mode[6] if len(mode) > 6 else {}
                            if mode_props.get("is-current", False):
                                mon_mode = mode[0]
                                break
                        break
                other_monitors.append(
                    dbus.Struct((
                        dbus.String(mon[0]),
                        dbus.String(mon_mode),
                        dbus.Dictionary({}, signature="sv"),
                    ), signature=None)
                )
            new_logical_monitors.append(
                dbus.Struct((
                    dbus.Int32(lm_x),
                    dbus.Int32(lm_y),
                    dbus.Double(lm_scale),
                    dbus.UInt32(lm_transform),
                    dbus.Boolean(lm_primary),
                    other_monitors,
                ), signature=None)
            )

    proxy = session_bus.get_object(
        "org.gnome.Mutter.DisplayConfig",
        "/org/gnome/Mutter/DisplayConfig",
    )
    iface = dbus.Interface(proxy, "org.gnome.Mutter.DisplayConfig")

    # method: 0 = verify (shows confirmation dialog), 1 = temporary, 2 = persistent
    try:
        iface.ApplyMonitorsConfig(
            dbus.UInt32(serial),
            dbus.UInt32(1),  # temporary — no confirmation dialog
            dbus.Array(new_logical_monitors, signature="(iiduba(ssssa{sv}))"),
            dbus.Dictionary({}, signature="sv"),
        )
        current_transform = transform
        print(f"Rotated display to transform {transform}")
    except dbus.exceptions.DBusException as e:
        print(f"ERROR applying rotation: {e}")


def on_properties_changed(interface_name, changed, invalidated, session_bus=None):
    """Handle orientation change from iio-sensor-proxy."""
    if interface_name != "net.hadess.SensorProxy":
        return
    orientation = changed.get("AccelerometerOrientation")
    if orientation is None:
        return

    orientation = str(orientation)
    transform = ORIENTATION_MAP.get(orientation)
    if transform is None:
        print(f"Unknown orientation: {orientation}")
        return

    print(f"Orientation changed: {orientation} -> transform {transform}")
    apply_rotation(session_bus, transform)


def main():
    DBusGMainLoop(set_as_default=True)

    system_bus = dbus.SystemBus()
    session_bus = dbus.SessionBus()

    # Claim the accelerometer so iio-sensor-proxy keeps running
    sensor_proxy = system_bus.get_object(
        "net.hadess.SensorProxy", "/net/hadess/SensorProxy"
    )
    sensor_iface = dbus.Interface(sensor_proxy, "net.hadess.SensorProxy")
    sensor_iface.ClaimAccelerometer()
    print("Claimed accelerometer from iio-sensor-proxy")

    # Get initial orientation
    props = dbus.Interface(sensor_proxy, "org.freedesktop.DBus.Properties")
    initial = str(props.Get("net.hadess.SensorProxy", "AccelerometerOrientation"))
    print(f"Initial orientation: {initial}")
    transform = ORIENTATION_MAP.get(initial, TRANSFORM_NORMAL)
    apply_rotation(session_bus, transform)

    # Listen for orientation changes
    system_bus.add_signal_receiver(
        lambda iface, changed, invalidated: on_properties_changed(
            iface, changed, invalidated, session_bus=session_bus
        ),
        signal_name="PropertiesChanged",
        dbus_interface="org.freedesktop.DBus.Properties",
        bus_name="net.hadess.SensorProxy",
        path="/net/hadess/SensorProxy",
    )

    print("Listening for orientation changes... (Ctrl+C to stop)")
    try:
        GLib.MainLoop().run()
    except KeyboardInterrupt:
        print("\nStopping autorotate daemon")
        sensor_iface.ReleaseAccelerometer()


if __name__ == "__main__":
    main()
