// Copyright (c) 2011, XMOS Ltd, All rights reserved
// This software is freely distributable under a derivative of the
// University of Illinois/NCSA Open Source License posted in
// LICENSE.txt and at <http://github.xcore.com/>

#define PS2_NONE    0
#define PS2_PRESS   1
#define PS2_RELEASE 2

#define PS2_MODIFIER_CTRL  1
#define PS2_MODIFIER_SHIFT 2
#define PS2_MODIFIER_CAPSL 4

struct ps2state {
    int mode;
    int bits;
    int valid;
    int value;
    int clockValue;
    int overrunErrors, parityErrors, stopErrors;
    int bit; /// this should not be in this structure but be a local var.
    int modifier;
    int released;
};

/** This function initialises the state structure that remembers the PS2
 * keyboard state (which bits have been received, which modifiers are
 * pressed, etc). It should be called prior to calling the ps2Handler() or
 * ps2Interpret() functions.
 *
 * \param ps2_clock the port that is connected to the PS2 clock signal.
 *                  This should be declared as an unbuffered non-directional
 *                  port.
 *
 * \param state    the variable that holds the PS2 state.
 **/
extern void ps2HandlerInit(port ps2_clock, struct ps2state &state) ;

/** This function is a select function that handles with data that comes in
 * on the PS2 I/O lines. It can either be called as a normal function, or
 * as part of a select statement. Its third parameter is a state variable
 * in which the received bits are stored. When a complete byte has been
 * received, the valid flag will be set, and the variable bits will hold
 * all eight bits. Instead of inspecting the state variable, the function
 * ps2Interpret can be called to retrieve the keys pressed/released.
 *
 * \param ps2_clock the port that is connected to the PS2 clock signal.
 *                  This should be declared as an unbuffered non-directional
 *                  port.
 *
 * \param ps2_data  the port that is connected to the PS2 data signal.
 *                  This should be declared as an unbuffered non-directional
 *                  port.
 *
 * \param clockBit  The bit number to which the clock is connected, 0 for a
 *                  one-bit port.
 *
 * \param state     the variable that holds the PS2 state.
 **/
extern select ps2Handler(port ps2_clock, port ps2_data, int clockBit,
                         struct ps2state &state);

/** This function can be called after hte ps2Handler function to interpret
 * whether anything interesting has happened. It returns three values: an
 * action (which is one of PS2_NONE, PS_PRESS, or PS2_RELEASE), a set of
 * modifiers (which is a combination of PS2_SHIFT, PS2_CTRL, PS2_EXT), and
 * a keycode. If PS2_NONE is returned, the key-code should be ignored. The
 * modifier is the current set of modifiers, and if PS2_PRESS or
 * PS2_RELEASE is returned, the third value is the keycode of the
 * pressed/released key.
 *
 * \param state     the variable that holds the PS2 state.
 */
{unsigned,unsigned,unsigned} extern ps2Interpret(struct ps2state &state) ;

/** This function looks up a key code and returns the code that the USB HID
 * keyboard spec expects, or -1 if the key cannot be mapped.
 *
 * \param keycode   keycode as returned by ps2Interpret()
 */
extern int ps2USB(unsigned int keycode) ;


/** (TODO) This function looks up a keycode and modifier and returns the ASCII equivalent
 * or -1 if the key cannot be mapped.
 *
 * \param modifier  modifier as returned by ps2Interpret()
 *
 * \param keycode   keycode as returned by ps2Interpret()
 */
extern int ps2ASCII(unsigned modifier, unsigned int keycode);
