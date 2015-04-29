# NixieClock
We (exco, kist, makefu and me) try to create a modular opensource nixie clock
The clock is based on a atmega32u4 esp8266 , there will be optional i²c rtc chip for good time accuray.

There will be three types of Modules
- HV Supply Module (contains max1771 stepup for generating Tube supply voltage)
- Controller Module (contains ESP8266 and RTC)
- Nixie Module (Contains 2 Nixies and two Attiny2313 i²c slaves)

maybe you find some additional information here
https://gum.krebsco.de/wiki/samu.html#nixie
https://excogitation.de/wiki/#IN-12A%20nixie%20clock
