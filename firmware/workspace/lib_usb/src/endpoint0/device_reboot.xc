// Copyright (c) 2016, XMOS Ltd, All rights reserved
#include <xs1.h>
#include <platform.h>
#include <xs1_su.h>
#include "xud.h"


#define XS1_SU_PERIPH_USB_ID 0x1

void do_device_reboot(void)
{
// This hack is for a bug in xTIMEcomposer 13.2.0 where write_periph_32 and read_periph32 do not have the correct settings for use in combinable

  asm(".globl read_periph_32.locnoside;.globl read_periph_32.locnochandec;.globl read_periph_32.locnoglobalaccess;.globl read_periph_32.locnointerfaceaccess;.globl read_periph_32.locnonotificationselect;.weak read_periph_32.locnoside;.weak read_periph_32.locnochandec;.weak read_periph_32.locnoglobalaccess;.weak read_periph_32.locnointerfaceaccess;.weak read_periph_32.locnonotificationselect;.set read_periph_32.locnoside, 1;.set read_periph_32.locnochandec, 1;.set read_periph_32.locnoglobalaccess, 1;.set read_periph_32.locnointerfaceaccess, 1;.set read_periph_32.locnonotificationselect, 1");

  asm(".globl write_periph_32.locnoside;.globl write_periph_32.locnochandec;.globl write_periph_32.locnoglobalaccess;.globl write_periph_32.locnointerfaceaccess;.globl write_periph_32.locnonotificationselect;.weak write_periph_32.locnoside;.weak write_periph_32.locnochandec;.weak write_periph_32.locnoglobalaccess;.weak write_periph_32.locnointerfaceaccess;.weak write_periph_32.locnonotificationselect;.set write_periph_32.locnoside, 1;.set write_periph_32.locnochandec, 1;.set write_periph_32.locnoglobalaccess, 1;.set write_periph_32.locnointerfaceaccess, 1;.set write_periph_32.locnonotificationselect, 1");


  asm(".globl write_sswitch_reg.locnoside;.globl write_sswitch_reg.locnochandec;.globl write_sswitch_reg.locnoglobalaccess;.globl write_sswitch_reg.locnointerfaceaccess;.globl write_sswitch_reg.locnonotificationselect;.weak write_sswitch_reg.locnoside;.weak write_sswitch_reg.locnochandec;.weak write_sswitch_reg.locnoglobalaccess;.weak write_sswitch_reg.locnointerfaceaccess;.weak write_sswitch_reg.locnonotificationselect;.set write_sswitch_reg.locnoside, 1;.set write_sswitch_reg.locnochandec, 1;.set write_sswitch_reg.locnoglobalaccess, 1;.set write_sswitch_reg.locnointerfaceaccess, 1;.set write_sswitch_reg.locnonotificationselect, 1");

  asm(".globl read_sswitch_reg.locnoside;.globl read_sswitch_reg.locnochandec;.globl read_sswitch_reg.locnoglobalaccess;.globl read_sswitch_reg.locnointerfaceaccess;.globl read_sswitch_reg.locnonotificationselect;.weak read_sswitch_reg.locnoside;.weak read_sswitch_reg.locnochandec;.weak read_sswitch_reg.locnoglobalaccess;.weak read_sswitch_reg.locnointerfaceaccess;.weak read_sswitch_reg.locnonotificationselect;.set read_sswitch_reg.locnoside, 1;.set read_sswitch_reg.locnochandec, 1;.set read_sswitch_reg.locnoglobalaccess, 1;.set read_sswitch_reg.locnointerfaceaccess, 1;.set read_sswitch_reg.locnonotificationselect, 1");


  asm(".globl write_sswitch_reg_no_ack.locnoside;.globl write_sswitch_reg_no_ack.locnochandec;.globl write_sswitch_reg_no_ack.locnoglobalaccess;.globl write_sswitch_reg_no_ack.locnointerfaceaccess;.globl write_sswitch_reg_no_ack.locnonotificationselect;.weak write_sswitch_reg_no_ack.locnoside;.weak write_sswitch_reg_no_ack.locnochandec;.weak write_sswitch_reg_no_ack.locnoglobalaccess;.weak write_sswitch_reg_no_ack.locnointerfaceaccess;.weak write_sswitch_reg_no_ack.locnonotificationselect;.set write_sswitch_reg_no_ack.locnoside, 1;.set write_sswitch_reg_no_ack.locnochandec, 1;.set write_sswitch_reg_no_ack.locnoglobalaccess, 1;.set write_sswitch_reg_no_ack.locnointerfaceaccess, 1;.set write_sswitch_reg_no_ack.locnonotificationselect, 1");

  asm(".globl write_node_config_reg.locnoside;.globl write_node_config_reg.locnochandec;.globl write_node_config_reg.locnoglobalaccess;.globl write_node_config_reg.locnointerfaceaccess;.globl write_node_config_reg.locnonotificationselect;.weak write_node_config_reg.locnoside;.weak write_node_config_reg.locnochandec;.weak write_node_config_reg.locnoglobalaccess;.weak write_node_config_reg.locnointerfaceaccess;.weak write_node_config_reg.locnonotificationselect;.set write_node_config_reg.locnoside, 1;.set write_node_config_reg.locnochandec, 1;.set write_node_config_reg.locnoglobalaccess, 1;.set write_node_config_reg.locnointerfaceaccess, 1;.set write_node_config_reg.locnonotificationselect, 1");

  asm(".globl get_local_tile_id.locnoside;.globl get_local_tile_id.locnochandec;.globl get_local_tile_id.locnoglobalaccess;.globl get_local_tile_id.locnointerfaceaccess;.globl get_local_tile_id.locnonotificationselect;.weak get_local_tile_id.locnoside;.weak get_local_tile_id.locnochandec;.weak get_local_tile_id.locnoglobalaccess;.weak get_local_tile_id.locnointerfaceaccess;.weak get_local_tile_id.locnonotificationselect;.set get_local_tile_id.locnoside, 1;.set get_local_tile_id.locnochandec, 1;.set get_local_tile_id.locnoglobalaccess, 1;.set get_local_tile_id.locnointerfaceaccess, 1;.set get_local_tile_id.locnonotificationselect, 1");


#if (XUD_SERIES_SUPPORT == XUD_U_SERIES)
    /* Disconnect from bus */
    unsigned data[] = {4};
    write_periph_32(usb_tile, XS1_SU_PERIPH_USB_ID, XS1_SU_PER_UIFM_FUNC_CONTROL_NUM, 1, data);

    /* Ideally we would reset SU1 here but then we loose power to the xcore and therefore the DFU flag */
    /* Disable USB and issue reset to xcore only - not analogue chip */
    write_node_config_reg(usb_tile, XS1_SU_CFG_RST_MISC_NUM,0b10);
#else
    unsigned int pllVal;
    unsigned int localTileId = get_local_tile_id();
    unsigned int tileId;
    unsigned int tileArrayLength;

    /* Find size of tile array - note in future tools versions this will be available from platform.h */
    asm volatile ("ldc %0, tile.globound":"=r"(tileArrayLength));

    /* Reset all remote tiles */
    for(int i = 0; i< tileArrayLength; i++)
    {
        /* Cannot cast tileref to unsigned! */
        tileId = get_tile_id(tile[i]);

        /* Do not reboot local tile yet! */
        if(localTileId != tileId)
        {
            read_sswitch_reg(tileId, 6, pllVal);
            write_sswitch_reg_no_ack(tileId, 6, pllVal);
        }
    }

    /* Finally reboot this tile! */
    read_sswitch_reg(localTileId, 6, pllVal);

    write_sswitch_reg_no_ack(localTileId, 6, pllVal);
#endif
}

