#include<SoftwareSerial.h>
#include <Servo.h>
#define SENSOR_COUNT 4  // 사용할 초음파 센서의 개수

// 각 센서의 Trig 핀과 Echo 핀 설정
int trigPins[SENSOR_COUNT] = {7, 7, 7, 7};  // Trig 핀 배열
int echoPins[SENSOR_COUNT] = {6, 4, 3, 5};  // Echo 핀 배열

long durations[SENSOR_COUNT];  // 각 센서의 거리 측정을 위한 시간 배열
long distances[SENSOR_COUNT];  // 각 센서의 거리 저장 배열

int angle; // 인식한 거 180 * (현재값)/ 127

Servo motor;  // 서보모터 변수 설정

int motorPin = 2;
int currpos=90;  // 서보모터 현재 위치
int pos = 0; //시리얼 통신으로 받는 값

bool flag_front = false;
int flag_left = 1;
int flag_back = 2;
int flag_right = 4;
int flag;

const int lowThreshold = 15;
const int highThreshold = 30;

int EN_A = 9;
int EN_B = 10;

// PA_1 : HIGH, PA_2 : LOw -> right back
// PA_1 : LOW, PA_2 : HIGH -> right go

int PA_1 = 11;
int PA_2 = 12;

// PB_1 : HIGH, PB_2 : LOw -> left go
// PB_1 : LOW, PB_2 : HIGH -> left back

int PB_1 = 8;
int PB_2 = 13;

int signalPin = A1;
int ffff = 0;

/////////////////////////////////////모터 제어
void motor_speed(int speedA, int speedB){
  analogWrite(EN_A, speedA);
  analogWrite(EN_B, speedB);
}

void motorStop(){
    digitalWrite(EN_A, 0);
    digitalWrite(EN_B, 0);
}

void right_back(){
    digitalWrite(PB_1, HIGH);
    digitalWrite(PB_2, LOW);
}

void right_go(){
    digitalWrite(PB_1, LOW);
    digitalWrite(PB_2, HIGH);
}

void left_back(){
    digitalWrite(PA_1, LOW);
    digitalWrite(PA_2, HIGH);
}

void left_go(){
    digitalWrite(PA_1, HIGH);
    digitalWrite(PA_2, LOW);
}
///////////////////////////// real move skrr
void back_straight(){
    motor_speed(250, 250);
    left_back();
    right_back();
}

void back_right(){
    motor_speed(250, 0);
    left_back();
    right_back();
}

void back_left(){
    motor_speed(0, 250);
    left_back();
    right_back();
}

void stop_left(){
    motor_speed(250, 250);
    left_go();
    right_back();
}

void stop_right(){
    motor_speed(250, 250);
    left_back();
    right_go();
}

void motorstop(){
    motor_speed(0, 0);
}



/////////////////////////////


void setup() {
  Serial.begin(9600);
  motor.attach(motorPin);
  // 각 센서의 핀 설정
  for (int i = 0; i < SENSOR_COUNT; i++) {
    pinMode(trigPins[i], OUTPUT);  // Trig 핀은 출력
    pinMode(echoPins[i], INPUT);   // Echo 핀은 입력
  }

  pinMode(EN_A, OUTPUT);
  pinMode(EN_B, OUTPUT);
  
  pinMode(PA_1, OUTPUT);
  pinMode(PA_2, OUTPUT);
  
  pinMode(PB_1, OUTPUT);
  pinMode(PB_2, OUTPUT);

  pinMode(A1, INPUT);

  motorStop();
  signalPin = A1;
}




void loop() {
  if (Serial.available() > 0) {  // 시리얼 데이터가 수신된 경우
    pos = Serial.read();  // 1바이트 데이터를 읽음
    if (pos != 0) {
      switch(pos){
        case 1: moveServo(currpos+30); break;
        case 2: moveServo(currpos+20); break;
        case 4: moveServo(currpos+10); break;
        case 8: moveServo(currpos); break;
        case 16: moveServo(currpos-10); break;
        case 32: moveServo(currpos-20); break;
        case 64: moveServo(currpos-30); break; 
        default: break; 
      }
    } 
  }
  for (int i = 0; i < SENSOR_COUNT; i++) {
      distances[i] = measureDistance(trigPins[i], echoPins[i]);
      if(distances[i] == 0 || distances[i] > 100) distances[i] = 100;
      
    }
  
    flag_front = false; 
    flag = 0;
  
    if(distances[0] < 100){ // 만약 앞쪽에 
      flag_front = true;
    }
  
    if(distances[1] < 30){ // 만약 왼쪽에
      flag += flag_left;
    }
  
    if(distances[2] < 30){ // 만약 뒤쪽에
      flag += flag_back;
    }
  
    if(distances[3] < 30){ // 만약 오른쪽에
      flag += flag_right;
    }
  
    move_motor(flag_front, flag);
    
    delay(50);  // 0.2초마다 갱신
}

void moveServo(int targetPos) {
  if (targetPos < 0 || targetPos > 180) return; // 유효한 각도 범위 확인
  int stepp = (targetPos > currpos) ? 1 : -1; // 각도 증가 또는 감소 설정
  for (int angle = currpos; angle != targetPos; angle += stepp) {
    motor.write(angle); // 각도 설정
    delay(15); // 부드러운 이동을 위한 딜레이 (300ms에서 줄임)
  }
  currpos = targetPos; // 현재 위치 업데이트
}

void move_motor(bool flag_front,int flag){
  if(flag_front){
    
    switch(flag){
        
        case 0:

        back_straight();
        // sensing front ---> move back
        break;

        case 1:

        back_right();
        // sensing front && left ----> move right && back;
        break;

        case 2:

        back_left();
        // sensing front && back ------> move left;
        break;

        case 3:

        back_right();
        // sensing front & left & back ----> move right;
        break;

        case 4:

        back_left();
        // sensing front & right -----> move back & left;
        break;

        case 5:

        motorStop();
        // sensing front & right & left ----> stop;
        break;


        case 6:

        back_left();
        // sensing front & back & right  ----> move left
        break;


        case 7:

        motorStop();
        break;
    }
    
  }

  else{
    
    motorStop();
  }
}


long measureDistance(int trigPin, int echoPin) {
    unsigned long startTime = micros();
    
    digitalWrite(trigPin, LOW);
    delayMicroseconds(2);
    digitalWrite(trigPin, HIGH);
    delayMicroseconds(10);
    digitalWrite(trigPin, LOW);

    while (digitalRead(echoPin) == LOW) {
        if (micros() - startTime > 15000) { 
            return 0; 
        }
    }

    unsigned long echoStart = micros();
    while (digitalRead(echoPin) == HIGH) {
        if (micros() - echoStart > 15000) { 
            return 0;
        }
    }

    unsigned long echoEnd = micros();
    
    long duration = echoEnd - echoStart;

    long distance = duration * 0.034 / 2; // cm 단위
    return distance;
}
