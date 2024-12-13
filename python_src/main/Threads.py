from flask import Flask, jsonify, request
from flask_cors import CORS
import random
import datetime
import time
import threading
import cv2
import requests  # requests 라이브러리 추가
import tensorflow as tf
import cv2
import serial
import numpy as np
import RPi.GPIO as GPIO
import time

buzzerPin = 17
noteDuration = 0.1
melody = [261, 294, 261, 294, 261, 294, 261, 294]  # C, D, E, F, G, A, B, C

SERVER_URL = "http://192.168.0.20:5200"
arduino_port = '/dev/tty/ACM0'  
baud_rate = 9600
ser = serial.Serial(arduino_port, baud_rate, timeout=1)
GPIO.setmode(GPIO.BCM)  # BCM 핀 번호 체계 사용
GPIO.setup(buzzerPin, GPIO.OUT)  

def playAlarm():
    global buzzerPin, noteDuration, melody
    for i in range(8):
        
        # 각 음에 맞는 주파수로 소리 낸 후 대기
        GPIO.output(buzzerPin, GPIO.HIGH)  # 소리 키기
        time.sleep(noteDuration)  # 노트 길이만큼 대기
        GPIO.output(buzzerPin, GPIO.LOW)  # 소리 끄기                                                  
        time.sleep(0.01)  # 소리 간의 짧은 간격


def getAlarmState():
    try:
        response = requests.get(f"{SERVER_URL}/getState")
        if response.status_code == 200:
            return response.json()  # 응답을 JSON 형식으로 반환
    except Exception as e:
        print(f"Error: {e}")
    return []

def alarm_thread(stop_event):
    
    global buzzerPin, noteDuration, melody


    while not stop_event.is_set():
        try:
            response = getAlarmState()  
            if response.state == 'on':
                playAlarm()
                time.sleep(0.1)
        except Exception as e:
            print(f"Error: {e}")
        time.sleep(1)

def image_thread(stop_event):
    MODEL_PATH = '/home/pi/osh/person.tflite'
    tflite = tf.lite.Interpreter(model_path=MODEL_PATH)
    tflite.allocate_tensors()

    input_details = tflite.get_input_details()
    output_details = tflite.get_output_details()
    input_size = input_details[0]['shape'][1:3]

    cap = cv2.VideoCapture(0)
    frame_counter = 0

    if not cap.isOpened():
        print("Error: Cannot access the camera.")
        return

    try:
        while not stop_event.is_set():
            ret, frame = cap.read()
            if not ret:
                break
            
            frame_counter += 1
            if frame_counter % 20 == 0:
                image_resized = cv2.resize(frame, (input_size[1], input_size[0]))
                image_resized = image_resized.astype(np.float32)
                image_resized = image_resized / 255.0  
                input_data = np.expand_dims(image_resized, axis=0) 
                

                tflite.set_tensor(input_details[0]['index'], input_data)
                tflite.invoke()

                detection_scores = tflite.get_tensor(output_details[0]['index'])[0]
                detection_boxes = tflite.get_tensor(output_details[1]['index'])[0]
                num_detections = int(tflite.get_tensor(output_details[2]['index'])[0])
                detection_classes = tflite.get_tensor(output_details[3]['index'])[0]

                detect = False

                if num_detections > 0:
                    i = 0
                    score = detection_scores[0]
                    detect = True

                if detect and 1.0 >= score > 0.5:
                    y_min, x_min, y_max, x_max = detection_boxes[i]
                    h, w, _ = frame.shape

                    y_min = int(y_min * h)
                    y_max = int(y_max * h)
                    x_min = int(x_min * w)
                    x_max = int(x_max * w)

                    w_mid = int(w // 2)
                    x_mid = (x_min + x_max) // 2

                    if not detect:
                        bit_val = 0
                    elif 0 <= x_mid < w / 7:
                        bit_val = 1
                    elif w / 7 <= x_mid < (2 * w) / 7:
                        bit_val = 2
                    elif (2 * w) / 7 <= x_mid < (3 * w) / 7:
                        bit_val = 4
                    elif (3 * w) / 7 <= x_mid < (4 * w) / 7:
                        bit_val = 8
                    elif (4 * w) / 7 <= x_mid < (5 * w) / 7:
                        bit_val = 16
                    elif (5 * w) / 7 <= x_mid < (6 * w) / 7:
                        bit_val = 32
                    elif (6 * w) / 7 <= x_mid < w:
                        bit_val = 64
                    else:
                        bit_val = 0

                    byte_data = bit_val.to_bytes(1, byteorder='big', signed=False)
                    ser.write(byte_data)
                    print(f"Sent move: {bit_val} (as byte {byte_data})")

                    cv2.rectangle(frame, (x_min, y_min), (x_max, y_max), (255, 0, 0), 2)
                    cv2.putText(frame, "Person", (x_min, y_min - 10), cv2.FONT_HERSHEY_SIMPLEX, 0.5, (255, 0, 0), 2)
            
            cv2.imshow('test', frame)

            if cv2.waitKey(33) & 0xFF == ord('q'):
                break

    finally:
        cap.release()
        cv2.destroyAllWindows()

if __name__ == '__main__':
    stop_event = threading.Event()

    alarmThread = threading.Thread(target=alarm_thread, args=(stop_event,), daemon=True)
    imageThread = threading.Thread(target=image_thread, args=(stop_event,), daemon=True)

    alarmThread.start()
    imageThread.start()

    try:
        while not stop_event.is_set():
            time.sleep(0.1)
    except KeyboardInterrupt:
        print("Exiting program.")
        stop_event.set()

    GPIO.cleanup()
    alarmThread.join()
    imageThread.join()
