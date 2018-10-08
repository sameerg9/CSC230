#include <string.h>
#include <stdlib.h>
#include <stdio.h>
#include <stdbool.h> // for pause toggle ... can replace with 1 or 0 logic if need to min space
#include "CSC230.h"
#include "CSC230_LCD.c"
#include <avr/io.h>

char* strOut ; 
char* prev ;
char* prev1 = "00:00"; 
char str[100];

char* timeCh; 
int ms =0 ; 
int sec =0;
int min = 0 ; 

int ms1 =0 ; 
int sec1 =0;
int min1 = 0 ;

 
int speed = 0; //init speed to 10 

bool pause = true; // start program on pause  
bool ignore = false ;  //init ignore to be false

//add speed variable 

//in button pause , check if pause ==0 , set to 1 , set ignore and set speed to 0 , 
		//else set pause to 1 , set ignore to 0 and set speed back to +_ 10 

int upCount = 0 ; //how many times we press the lap button


#define  ADC_BTN_RIGHT 0x032
#define  ADC_BTN_UP 0x0C3
#define  ADC_BTN_DOWN 0x17C
#define  ADC_BTN_LEFT 0x22B
#define  ADC_BTN_SELECT 0x316


//This global variable is used to count the number of interrupts
//which have occurred. Note that 'int' is a 16-bit type in this case.
int interrupt_count = 0;

//Global variable to track the state of the LED on pin 52.
int LED_state = 0;


//Define the ISR for the timer 0 overflow interrupt.

ISR(TIMER0_OVF_vect){


		
		interrupt_count = interrupt_count+speed;
	
	//Every 61 interrupts, flip the LED value
	if (interrupt_count >= 61){ //was at 6 
		interrupt_count -= 61;
		ms++; //increment milliseconds on 61 interrupts  

	}
	if(ms >= 9){ 
		ms=0 ;
		sec++;
	}
	if(sec > 59 ){
		sec = 0 ; 
		min ++; 
	}
		
		
		
	if(min >= 99){ //if we reach 99 mins , reset to 0 
		min =0 ; 
		sec = 0; 
		ms = 0 ; 
		pause = true ; 
	
	 }
	 
	 sprintf(strOut, " %02i:%02i.%i", min,sec, ms);
	 timeCh = strOut;
}


// timer0_setup()
// Set the control registers for timer 0 to enable
// the overflow interrupt and set a prescaler of 1024.
void timer0_setup(){
	//You can also enable output compare mode or use other
	//timers (as you would do in assembly).

	TIMSK0 = 0x01;
	TCNT0 = 0x00;
	TCCR0A = 0x00;
	TCCR0B = 0x05; //Prescaler of 1024
}

void init_buttons(){  
	ADCSRA = 0x87;
	ADMUX = 0x40;
}
unsigned short poll_adc(){
	unsigned short adc_result = 0; //16 bits
	
	ADCSRA |= 0x40;
	while((ADCSRA & 0x40) == 0x40); //Busy-wait
	
	unsigned short result_low = ADCL;
	unsigned short result_high = ADCH;
	
	adc_result = (result_high<<8)|result_low;
	return adc_result;
}
//button functionality
void buttonCheck(){  
		

	short adc_result = poll_adc();

	if(adc_result >= ADC_BTN_LEFT && adc_result < ADC_BTN_SELECT){
	//select button pressed ; 
		if(ignore == false ){

			if(pause){  // 

				speed = 10;
				pause = false; 
				ignore = true; 	
		
			} else {
	
				speed = 0 ;
				pause = true;
				ignore = true;
			}
		}	
	}


	else if(adc_result >= ADC_BTN_DOWN && adc_result < ADC_BTN_LEFT){
		//left button 
		pause = true;
		speed = 0; //reset on pause 
		min =0 ; 
		sec = 0; 
		ms = 0 ;
		ms1 =0 ; 
		sec1 =0;
		min1 = 0 ; 
		sprintf(strOut, "%02d:%02d.%d",min, sec, ms);
	}

		
	else if(adc_result >= ADC_BTN_RIGHT && adc_result < ADC_BTN_UP){
		//up button pressed 
			//put first lap in bottom left 
		if (ignore == 1) { 
		} else {
			// place the first lap (empty first press , will be lap 2 on second press as vars updated) in the bottom left corner 
			sprintf(str, "%02d:%02d.%d",min1, sec1, ms1);
			lcd_xy(0,1);
			lcd_puts(str); 
			
		
			min1 = min; 
			sec1 = sec ; 
			ms1 = ms ; // copy for lap 1 
			
			
			sprintf(str, "%02d:%02d.%d",min1, sec1, ms1); // place lap 1 in bottom right corner 
			lcd_xy(9,1); 
			lcd_puts(str);
			
			ignore = 1;  //enable ignore 
		}
			
			
		
	}	
	
	else if(adc_result >= ADC_BTN_UP && adc_result < ADC_BTN_DOWN){
	//down button pressed. Clear laps 

		lcd_xy(0,1);
		lcd_puts("                  "); 
		ms1 =0 ; 
		sec1 =0;
		min1 = 0 ; 
	//*/
	
	}
	
else{
		ignore = false; 
	}

}

int main(){

	strOut = " 00:00.0";
	timeCh = "Time: " ;
	//Set data direction for Port B
	//DDRB = 0xff;

	timer0_setup();
	init_buttons();
	lcd_init();
	sei(); 



	while(1){
		
		lcd_xy(0,0);
		lcd_puts("Time: "); 


		lcd_xy(5,0);
		lcd_puts(strOut); 
		buttonCheck(); 
			

	}
	
}
