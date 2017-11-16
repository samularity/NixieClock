/*
*************************************************************************************************
*
* 	attiny2313 GPIO-Portexpander I²C Slave using USI                               
* 	based on http://www.mikrocontroller.net/attachment/highlight/12871                      
*	Samuel Munz 
* 
**************************************************************************************************

runs on 8 Mhz internal oscillator
Fuse settings (make wrfuse8mhz):
H Fuse: 0xDF
L Fuse: 0xE4
E Fuse: 0xFF

i²c base adress can be selected in #define USI_ADDRESS below, 
the offset from the base can be selected by connecting PB0 PB1 and PB2 to GND
PB0 adds addr+1
PB1 adds addr+2
PB2 adds addr+4 


Pinout:
Nixie	Pin
0		PA0
1		PD0
2		PD1
3		PD2
4		PD3
5		PD4
6		PD5
7		PD6
8		PB6
9		PA1
Dot		PB4
 

(1)		reset	
(2)		PD0		Nixie 1
(3)		PD1		Nixie 2
(4)		PA1		Nixie 9
(5)		PA0		Nixie 0
(6)		PD2		Nixie 3
(7)		PD3		Nixie 4
(8)		PD4		Nixie 5
(9)		PD5		Nixie 6
(10)	GND

(11)	PD6		Nixie 7
(12)	PB0		I²C ADDR Bit 0
(13)	PB1		I²C ADDR Bit 1
(14)	PB2		I²C ADDR Bit 2
(15)	PB3		
(16)	PB4		Nixie Dot
(17)	PB5		SDA     		| ISP-MOSI
(18)	PB6		Nixie 8		 	| ISP-MISO
(19)	PB7		SCK     		| ISP-SCK
(20)	Vcc		3v3

*/


#include <avr/io.h>
#include <avr/interrupt.h>
#define F_CPU 8000000UL  // 8 MHz
#include <util/delay.h>

//edit i²c base adress here
#define USI_ADDRESS			0x10 //max 0x10 + 7

#define USI_DATA   			USIDR
#define USI_STATUS  		USISR
#define USI_CONTROL 		USICR

#define NONE				0
#define ACK_PR_RX			1
#define BYTE_RX				2
#define ACK_PR_TX			3
#define PR_ACK_TX			4
#define BYTE_TX				5

#define DDR_USI             DDRB
#define PORT_USI            PORTB
#define PIN_USI             PINB
#define PORT_USI_SDA        PORTB5
#define PORT_USI_SCL        PORTB7

volatile uint8_t COMM_STATUS = NONE;
void sleep_us(uint16_t us);
void sleep_ms(uint16_t ms);
void USI_init(void);

#define	SET_HIGH(s)		PORTD |= (1<<s);	//PD high
#define SET_LOW(s)		PORTD &= ~(1<<s);	//PD low

volatile uint8_t _DeviceAdress = USI_ADDRESS;
volatile uint8_t _ReceivedByte=0;

int main(void) {

	//set gpios as output
	DDRA |= ( (1<<0) | (1<<1));// set as PortA as output
	DDRD = 0xFF;  // set as PortD as output
	DDRB |= (1<<4);
	//Set choosen outputs low
	PORTA &= ~( (1<<0) | (1<<1)) ;//just 0 and 1
	PORTD = 0x00; //all pins

	//set gpios as input to generate i²c adress offset
	DDRB  &=~( (1<<0) | (1<<1) | (1<<2) );//set direction
	PORTB |= ( (1<<0) | (1<<1) | (1<<2) );//activate pullup
	sleep_us(10);//wait for pullup
	uint8_t _offset = PINB & ( (1<<0)|(1<<1)|(1<<2) );//read pb0 pb1 pb2 pb3
	_offset = 0x7 & (~_offset);//calculate offset
	_DeviceAdress += _offset; //add offset to base adress
	USI_init(); //init i²c
	sleep_us(10);//just wait for all the registers to be set
	
	sei(); //enable interrupts

    _ReceivedByte=0x00;
	while(1){
		//all off
		PORTA &= ~( (1<<PA0) | (1<<PA1) );
		PORTB &= ~( (1<<PB4) | (1<<PB6) );
		PORTD = 0x00;

		//check _ReceivedByte and set the choosen
		switch(_ReceivedByte & 0b00001111)
		{
			case 0: PORTA |= (1<<0); break; //number 0
			case 1: PORTD |= (1<<0); break;
			case 2: PORTD |= (1<<1); break;
			case 3: PORTD |= (1<<2); break;
			case 4: PORTD |= (1<<3); break;
			case 5: PORTD |= (1<<4); break;
			case 6: PORTD |= (1<<5); break;
			case 7: PORTD |= (1<<6); break;
			case 8: PORTB |= (1<<6); break;
			case 9: PORTA |= (1<<1); break;
			default: break;	//none - all off
		}
		if ( 0b00010000 == (_ReceivedByte & 0b00010000) )
		{
			PORTB |= (1<<4);
		}
/*        
        switch(_ReceivedByte & 0b00010000) //enable or disable dot
		{
			case 0b00010000: PORTB |= (1<<4); break; //dot on
            default: PORTB &= ~ (1<<4); break;	//dot off
        }
*/        
		sleep_ms(10);//wait a little
	}
	return 0;
}

void USI_init(void) {
	// 2-wire mode; Hold SCL on start and overflow; ext. clock
	USI_CONTROL |= (1<<USIWM1) | (1<<USICS1);
	USI_STATUS = 0xf0;  // write 1 to clear flags, clear counter
	DDR_USI  &= ~(1<<PORT_USI_SDA);
	PORT_USI &= ~(1<<PORT_USI_SDA);
	DDR_USI  |=  (1<<PORT_USI_SCL);
	PORT_USI |=  (1<<PORT_USI_SCL);
	// startcondition interrupt enable
	USI_CONTROL |= (1<<USISIE);
}

ISR(USI_START_vect) {
	//uncomment two lines below if its broken
	//uint8_t tmpUSI_STATUS;
	//tmpUSI_STATUS = USI_STATUS;
	COMM_STATUS = NONE;
	// Wait for SCL to go low to ensure the "Start Condition" has completed.
	// otherwise the counter will count the transition
	while ( (PIN_USI & (1<<PORT_USI_SCL)) );
	USI_STATUS = 0xf0; // write 1 to clear flags; clear counter
	// enable USI interrupt on overflow; SCL goes low on overflow
	USI_CONTROL |= (1<<USIOIE) | (1<<USIWM0);
}

ISR(USI_OVERFLOW_vect) {//USI_TWI_Overflow_State
	uint8_t BUF_USI_DATA = USI_DATA;
	switch(COMM_STATUS) {
		case NONE:
		if (((BUF_USI_DATA & 0xfe) >> 1) != _DeviceAdress) {	// if not receiving my address
			// disable USI interrupt on overflow; disable SCL low on overflow
			USI_CONTROL &= ~((1<<USIOIE) | (1<<USIWM0));
		}
		else { // else address is mine
			DDR_USI  |=  (1<<PORT_USI_SDA);
			USI_STATUS = 0x0e;	// reload counter for ACK, (SCL) high and back low
			if (BUF_USI_DATA & 0x01) COMM_STATUS = ACK_PR_TX; else COMM_STATUS = ACK_PR_RX;
		}
		break;
		case ACK_PR_RX:
		DDR_USI  &= ~(1<<PORT_USI_SDA);
		COMM_STATUS = BYTE_RX;
		break;
		case BYTE_RX:
		/* Save received byte here! ... = USI_DATA*/
		_ReceivedByte= USI_DATA;
		DDR_USI  |=  (1<<PORT_USI_SDA);
		USI_STATUS = 0x0e;	// reload counter for ACK, (SCL) high and back low
		COMM_STATUS = ACK_PR_RX;
		break;
		case ACK_PR_TX:
		/* Put first byte to transmit in buffer here! USI_DATA = ... */
		PORT_USI |=  (1<<PORT_USI_SDA); // transparent for shifting data out
		COMM_STATUS = BYTE_TX;
		break;
		case PR_ACK_TX:
		if(BUF_USI_DATA & 0x01) {
			COMM_STATUS = NONE; // no ACK from master --> no more bytes to send
		}
		else {
			/* Put next byte to transmit in buffer here! USI_DATA = ... */
			//USI_DATA = _offset; //TODO remove this line
			PORT_USI |=  (1<<PORT_USI_SDA); // transparent for shifting data out
			DDR_USI  |=  (1<<PORT_USI_SDA);
			COMM_STATUS = BYTE_TX;
		}
		break;
		case BYTE_TX:
		DDR_USI  &= ~(1<<PORT_USI_SDA);
		PORT_USI &= ~(1<<PORT_USI_SDA);
		USI_STATUS = 0x0e;	// reload counter for ACK, (SCL) high and back low
		COMM_STATUS = PR_ACK_TX;
		break;
	}
	USI_STATUS |= (1<<USIOIF); // clear overflow-interruptflag, this also releases SCL
}

void sleep_ms(uint16_t ms){
	while(ms){
		ms--;
		_delay_ms(1);
	}
}

void sleep_us(uint16_t us){
	while(us){
		us--;
		_delay_us(1);
	}
}
