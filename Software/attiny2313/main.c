/*
Attiny2313 used as GPIO-Port expander
Communication over I²C, attiny acts as slave
Pinout:
(1)		reset- mit pullup auf vcc
(2-9) 	GPIO - frei 8x
(10) 	GND	 -
(11-16)	GPIO -frei 6x
(17) 	PB5  - SDA
(18) 	GPIO - frei
(19)	PB7  - SCL
(20)	VCC  - 3v3

3 Pins as Input Pullup activated, used to select i²c adress offset
i²c start adress is defined below
3 Pins -> max 8 adress
4 pins -> max 16 adress
*/
/*
*************************************************************************************************
* attiny2313 I²C Slave using USI                               
* Samuel Munz
* based on http://www.mikrocontroller.net/attachment/highlight/12871                      
**************************************************************************************************
*/

#include <avr/io.h>
#include <avr/interrupt.h>
#define F_CPU 8000000UL  // 8 MHz
#include <util/delay.h>

#define USI_DATA   			USIDR
#define USI_STATUS  		USISR
#define USI_CONTROL 		USICR
#define USI_ADDRESS			0x20

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
void sleep_ms(uint16_t ms);
void USI_init(void);

#define toggle(s) 		PORTD^=(1<<s);	//toggelt einen pin
#define	SET_HIGH(s)		PORTD |= (1<<s);	//PD high
#define SET_LOW(s)		PORTD &= ~(1<<s);	//PD low

volatile uint8_t _DeviceAdress=USI_ADDRESS;
volatile uint8_t _ReceivedByte=0;


int main(void) {

	//set gpios as output
	DDRA |= ( (1<<PA0) | (1<<PA1));// set as PortA as output
	DDRD = 0xFF;  // set as PortD as output

	//Set choosen outputs low
	PORTA &= ~( (1<<PA0) | (1<<PA1)) ;//just 0 and 1
	PORTD = 0x00; //all pins

	//set gpios as input to generate i²c adress offset
	DDRB  &=~( (1<<PB0) | (1<<PB1) | (1<<PB2) | (1<<PB3) );//set direction
	PORTB |= ( (1<<PB0) | (1<<PB1) | (1<<PB2) | (1<<PB3) );//activate pullup

	uint8_t _offset = PINB & ( (1<<PB0)|(1<<PB1)|(1<<PB2)|(1<<PB3) );//read pb0 pb1 pb2 pb3
	_offset = 0xF & (~_offset);//calculate offset
	_DeviceAdress += _offset; //add offset to base adress
	
	USI_init(); //init i²c
	sei(); //enable interrupts

	while(1){
		//all off
		PORTA &= ~( (1<<PA0) | (1<<PA1)) ;
		PORTD = 0x00;
		
		//check _ReceivedByte and set the choosen
		switch(_ReceivedByte)
		{
			case 0: PORTD |= (1<<0); break; //number 0
			case 1: PORTD |= (1<<1); break;
			case 2: PORTA |= (1<<1); break;
			case 3: PORTA |= (1<<0); break;
			case 4: PORTD |= (1<<2); break;
			case 5: PORTD |= (1<<3); break;
			case 6: PORTD |= (1<<4); break;
			case 7: PORTD |= (1<<5); break;
			case 8:
			case 9:
			case 10: //to number 10
			case 11: //upper point
			case 12: //lower point
			default: break;	//none - all off
		}
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

ISR(USI_START_vect) {//ISR(SIG_USI_START) {
	//uncomment two lines below if its broken
	//uint8_t tmpUSI_STATUS;
	//tmpUSI_STATUS = USI_STATUS;
	//COMM_STATUS = NONE;
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
