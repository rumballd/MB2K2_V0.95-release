// Copyright (c) 2016, XMOS Ltd, All rights reserved
#ifndef __usb_endpoint0_h__
#define __usb_endpoint0_h__
/* Experimental features.
   The features in this file are **experimental**,
   not supported and not known to work if enabled. Any guarantees of
   the robustness of the component made by XMOS do not hold if these features
   are used.
*/

/*************** ENDPOINT0 CALLBACKS ************************/

#ifdef __XC__
typedef struct ep0_descriptor {
  const char * unsafe desc;
  size_t len;
} ep0_descriptor;
#else
typedef struct ep0_descriptor {
  const char * desc;
  size_t len;
} ep0_descriptor;
#endif

#ifdef __XC__

/** Endpoint 0 callback interface.
 *
 *  Interface allowing applications to provide specific interface
 *  descriptor information and behavior to the Endpoint 0 component.
 */
typedef interface usb_ep0_callback_if {
  /** Request to register interface information.
   *
   *  This function is called on startup to allow the application
   *  to describe which USB interfaces it wishes to register.
   *
   *  \param string_table_offset  The current offset in the string table
   *                              during registration. All the application
   *                              interface descriptors should be patched
   *                              so that string indices in the descriptor
   *                              start from this value.
   *  \param interface_num_hs_offset
   *                              The current offset in the high speed
   *                              interface list during registration.
   *                              All the application
   *                              interface descriptors should be patched
   *                              so that any interface numbers start
   *                              start from this value.
   *  \param interface_num_fs_offset
   *                              The current offset in the full speed
   *                              interface list during registration.
   *                              All the application
   *                              interface descriptors should be patched
   *                              so that any interface numbers start
   *                              start from this value.
   *  \param num_interfaces_hs    The application should set this value to
   *                              the number of high-speed
   *                              interfaces being registered.
   *  \param num_interfaces_fs    The application should set this value to
   *                              the number of full-speed
   *                              interfaces being registered.
   *  \param num_strings          The application should set this value to
   *                              the number of strings the application wants
   *                              to register in the string table.
   */
  void register_interfaces(size_t string_table_offset,
                           size_t interface_num_hs_offset,
                           size_t interface_num_fs_offset,
                           size_t &num_interfaces_hs,
                           size_t &num_interfaces_fs,
                           size_t &num_strings);

  /** Request an interface descriptor.
   *
   *  This is called by the Endpoint 0 component during enumeration so that
   *  the application can provide an interface descriptor.
   *
   *  \param speed               The speed that the USB bus has enumerated at.
   *  \param index               The index of the interface to provide
   *                             (relative to this connection, so 0 would be
   *                              a request for the first interface that has
   *                              been registered).
   *  \param descs               This reference parameter should be set to
   *                             a pointer to an array of ``ep0_desciptor``
   *                             data structures that provide the interface
   *                             descriptor when concatenated.
   *  \param num                 The reference parameter should be set to the
   *                             size of the ``descs`` array.
   */
  void get_interface_descriptor(XUD_BusSpeed_t speed,
                                size_t index,
                                const ep0_descriptor * unsafe &descs,
                                size_t &num);

  /** Request a string table entry.
   *
   *  This is called by the Endpoint 0 component to get a string table
   *  entry from the application.
   *
   *  \param     index      The index (relative to the app and starting at 0)
   *                        of the string to get.
   *  \param     str        This reference parameter should be set to a pointer
   *                        to the string.
   */
  void get_string(size_t index,
                  const char * unsafe &str);

  /** USB Connection callback.
   *
   *  This callback is called by Endpoint 0 when the device connects to the
   *  host.
   *
   *  \param speed   The speed the device has connected at.
   *  \param in_dfu_mode Set to 1 if the device is in DFU mode, 0 otherwise.
   */
  void connected(XUD_BusSpeed_t speed, int in_dfu_mode);

  /** Pre DFU reboot callback.
   *
   *  This callback is called by Endpoint 0 just before the device is about
   *  to reboot into DFU mode.
   */
  void pre_dfu_reboot(void);

  /** Handle an interface request.
   *
   *  This callback is called by Endpoint 0 when the host performs an interface
   *  specific request.
   *
   *  \param ep0_out    Endpoint 0 data structure that can be used to
   *                    make XUD API calls.
   *  \param ep0_in     Endpoint 0 data structure that can be used to
   *                    make XUD API calls.
   *  \param sp         Data structure describing the host request.
   *  \param result     The application should set this to indicate the
   *                    result of the request handling (see XUD API
   *                    for details).
   */
  void handle_request(XUD_ep ep0_out,
                      XUD_ep ep0_in,
                      USB_SetupPacket_t sp,
                      XUD_Result_t &result);

} usb_ep0_callback_if;

enum ep0_support_type {
  USB_SUPPORT_FS_AND_HS,
  USB_SUPPORT_HS_ONLY,
  USB_SUPPORT_FS_ONLY
};

typedef interface usb_dfu_callback_if {

  void start_image_write(void);
  void write_block(unsigned char * data, size_t len);
  void end_image_write(void);

  void start_image_read(void);
  size_t read_block(unsigned char * data);

  void revert_to_factory_image(void);
  void select_image(unsigned id);

} usb_dfu_callback_if;

#define USB_MAX_STR_TABLE_ENTRY_SIZE 60

/** Endpoint0 control task.
 *
 *  This task implements a handler for USB Endpoint 0 control packets. It
 *  handles enumeration, reset and configuration requests.
 *
 *  \param c_ep_out    Channel to connect to the first element of the
 *                     OUT endpoint array parameter fo the XUD component.
 *  \param c_ep_in     Channel to connect to the first element of the
 *                     IN endpoint array parameter fo the XUD component.
 *  \param ep0_support_type
 *                     Argument specifying what speed the device should support
 *                     (either ``USB_SUPPORT_HS_ONLY``, ``USB_SUPPORT_FS_ONLY``
 *                      or ``USB_SUPPORT_FS_AND_HS``).
 *  \param vendorName  String argument containing the vendor name for the
 *                     device descriptor.
 *  \param vendorId    The vendor ID for the device descriptor.
 *  \param productName String argument containing the product name for the
 *                     device descriptor.
 *  \param productId   The product ID for the device descriptor when
 *                     enumerating as a high speed device.
 *  \param productId_fs
 *                     The product ID for the device descriptor when
 *                     enumerating as a full speed device.
 *  \param majorVersion
 *                     The major version of the device for the device
 *                     descriptor.
 *  \param minorVersion
 *                     The minor version of the device for the device
 *                     descriptor.
 *  \param subMinorVersion
 *                     The sub-minor (point) version of the device for
 *                     the device descriptor.
 *  \param i_dfu       This interface should be connected to the application
 *                     to provide behavior for DFU operations. If DFU is
 *                     not required then ``null`` should be passed in to
 *                     this argument.
 *  \param i_ep0       An array of callback interfaces to connect to the
 *                     application to provide specific interface descriptors
 *                     and behavior.
 *  \param n           The number of callback interfaces required.
 */
/*[[combinable]]
void usb_endpoint0(chanend c_ep_out, chanend c_ep_in,
                   enum ep0_support_type support_type,
                   const char *vendorName,
                   unsigned vendorId,
                   const char *productName,
                   unsigned productId,
                   unsigned productId_fs,
                   unsigned majorVersion,
                   unsigned minorVersion,
                   unsigned subMinorVersion,
                   client usb_dfu_callback_if ?i_dfu,
                   client usb_ep0_callback_if i_ep0[n],
                   static const size_t n);

[[distributable]]
void dfu_flash(server usb_dfu_callback_if dfu,
               in buffered port:8 p_spi_miso,
               out port p_spi_ss,
               out port p_spi_clk,
               out buffered port:8 p_spi_mosi,
               clock clk_spi,
               const fl_DeviceSpec spec[n],
               size_t n,
               size_t maxsize,
               static const size_t pagesize);
*/
#endif // __XC__



#endif // __usb_endpoint0_h__

