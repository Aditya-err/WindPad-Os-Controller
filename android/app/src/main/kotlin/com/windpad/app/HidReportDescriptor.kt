package com.windpad.app

object HidReportDescriptor {
    val MOUSE_DESCRIPTOR = byteArrayOf(
        0x05.toByte(), 0x01,        // Usage Page (Generic Desktop)
        0x09.toByte(), 0x02,        // Usage (Mouse)
        0xA1.toByte(), 0x01,        // Collection (Application)
        0x85.toByte(), 0x01,        //   Report ID (1)
        0x09.toByte(), 0x01,        //   Usage (Pointer)
        0xA1.toByte(), 0x00,        //   Collection (Physical)
        0x05.toByte(), 0x09,        //     Usage Page (Buttons)
        0x19.toByte(), 0x01,        //     Usage Minimum (1)
        0x29.toByte(), 0x03,        //     Usage Maximum (3)
        0x15.toByte(), 0x00,        //     Logical Minimum (0)
        0x25.toByte(), 0x01,        //     Logical Maximum (1)
        0x95.toByte(), 0x03,        //     Report Count (3)
        0x75.toByte(), 0x01,        //     Report Size (1)
        0x81.toByte(), 0x02,        //     Input (Data, Variable, Absolute)
        0x95.toByte(), 0x01,        //     Report Count (1)
        0x75.toByte(), 0x05,        //     Report Size (5) — padding
        0x81.toByte(), 0x03,        //     Input (Constant)
        0x05.toByte(), 0x01,        //     Usage Page (Generic Desktop)
        0x09.toByte(), 0x30,        //     Usage (X)
        0x09.toByte(), 0x31,        //     Usage (Y)
        0x09.toByte(), 0x38,        //     Usage (Wheel)
        0x15.toByte(), 0x81.toByte(),//    Logical Minimum (-127)
        0x25.toByte(), 0x7F,        //     Logical Maximum (127)
        0x75.toByte(), 0x08,        //     Report Size (8)
        0x95.toByte(), 0x03,        //     Report Count (3)
        0x81.toByte(), 0x06,        //     Input (Data, Variable, Relative)
        0xC0.toByte(),              //   End Collection
        0xC0.toByte()               // End Collection
    )

    val KEYBOARD_DESCRIPTOR = byteArrayOf(
        0x05.toByte(), 0x01,  // Usage Page (Generic Desktop)
        0x09.toByte(), 0x06,  // Usage (Keyboard)
        0xA1.toByte(), 0x01,  // Collection (Application)
        0x85.toByte(), 0x02,  //   Report ID (2)
        0x05.toByte(), 0x07,  //   Usage Page (Key Codes)
        0x19.toByte(), 0xE0.toByte(), // Usage Minimum (224) — modifiers
        0x29.toByte(), 0xE7.toByte(), // Usage Maximum (231)
        0x15.toByte(), 0x00,  //   Logical Minimum (0)
        0x25.toByte(), 0x01,  //   Logical Maximum (1)
        0x75.toByte(), 0x01,  //   Report Size (1)
        0x95.toByte(), 0x08,  //   Report Count (8)
        0x81.toByte(), 0x02,  //   Input (Data, Variable, Absolute) — modifier byte
        0x95.toByte(), 0x01,  //   Report Count (1)
        0x75.toByte(), 0x08,  //   Report Size (8)
        0x81.toByte(), 0x03,  //   Input (Constant) — reserved byte
        0x95.toByte(), 0x06,  //   Report Count (6)
        0x75.toByte(), 0x08,  //   Report Size (8)
        0x15.toByte(), 0x00,  //   Logical Minimum (0)
        0x25.toByte(), 0x65,  //   Logical Maximum (101)
        0x05.toByte(), 0x07,  //   Usage Page (Key Codes)
        0x19.toByte(), 0x00,  //   Usage Minimum (0)
        0x29.toByte(), 0x65,  //   Usage Maximum (101)
        0x81.toByte(), 0x00,  //   Input (Data, Array)
        0xC0.toByte()         // End Collection
    )

    val CONSUMER_DESCRIPTOR = byteArrayOf(
        0x05.toByte(), 0x0C,        // Usage Page (Consumer)
        0x09.toByte(), 0x01,        // Usage (Consumer Control)
        0xA1.toByte(), 0x01,        // Collection (Application)
        0x85.toByte(), 0x03,        //   Report ID (3)
        0x15.toByte(), 0x00,        //   Logical Minimum (0)
        0x26.toByte(), 0xFF.toByte(), 0x03, //   Logical Maximum (1023)
        0x19.toByte(), 0x00,        //   Usage Minimum (0)
        0x2A.toByte(), 0xFF.toByte(), 0x03, //   Usage Maximum (1023)
        0x75.toByte(), 0x10,        //   Report Size (16)
        0x95.toByte(), 0x01,        //   Report Count (1)
        0x81.toByte(), 0x00,        //   Input (Data, Array, Absolute)
        0xC0.toByte()               // End Collection
    )
}
