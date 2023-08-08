# Sample alarm app (flutter + kotlin)
An flutter sample app that can been used as alarm clock app, It can for now only been used on android devices as we build some native code,
The reason of the native code is that there where no good solution to show an full intent screen when the time has been triggered.  
(even on background or doze mode)  
<img src="res/alarm_list_screen.png" width="25%"/>
<img src="res/alarm_intent_screen.png" width="23%"/>
<img src="res/alarm_triggered.png" width="25%"/>
<img src="res/alarm_snoozed.png" width="25%"/>

## How to run:
`flutter run` in ./src/Alarm.Client folder

#### Still having some improvements:
- Can't trigger FCM to the custom native code as the MethodChannel is set on the foreground and not been set on the Background in android.
- show the full intent screen on the lock screen.
- 