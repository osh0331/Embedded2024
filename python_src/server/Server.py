from flask import Flask, jsonify, request
from flask_cors import CORS
import random
import datetime
import time
import threading

app = Flask(__name__)
CORS(app)

alarmStrengths = ['약', '중', '강']
alarms = []
alarmSounds = ['기본 알람음', '알람음 2', '알람음 3', '알람음 4', '알람음 5']
alarmSound = None
alarmVolume = 0

alarm_activated = False

def alarmCheck():
    global alarms, alarm_activated
    while True:
        now = datetime.datetime.now()
        to_remove = []
        
        for alarm in alarms: # 시간 된 경우
            if now >= alarm['time']:
                print(f"Triggering alarm: {alarm['name']} at {alarm['time']}")
                alarm_activated = True
                to_remove.append(alarm)
        
        for alarm in to_remove:
            alarms.remove(alarm)
            print(f"Alarm removed: {alarm['name']} at {alarm['time']}")
        
        time.sleep(1)  # 1초마다 확인

@app.route('/getState', methods = ['GET'])
def getState():
    global alarm_activated
    if alarm_activated == True:
        return jsonify({'state' : 'on'})
    else:
        return jsonify({'state' : 'off'})

@app.route('/offAlarm', methods = ['POST'])
def changeState():
    global alarm_activated
    alarm_activated = False
    return jsonify({'state' : 'off'})

@app.route('/addAlarm', methods=['POST'])
def add_alarm():
    data = request.form
    name = data.get('name')
    time_str = data.get('time')
    
    time = datetime.datetime.fromisoformat(time_str)
    
    alarms.append({'name': name, 'time': time})
    print(f"Alarm added: {name} at {time}")
    
    return jsonify({'status': 'success', 'alarms': alarms}), 200

@app.route('/removeAlarm', methods=['POST'])
def remove_alarm():
    data = request.form
    name = data.get('name')
    time_str = data.get('time')
    
    time = datetime.datetime.fromisoformat(time_str)
    
    global alarms
    alarms = [a for a in alarms if not (a['name'] == name and a['time'] == time)]

    print(alarms)
    print(f"Alarm removed: {name} at {time}")
    
    return jsonify({'status': 'success', 'alarms': alarms}), 200

@app.route('/setAlarmSound', methods=['POST'])
def setAlarmSound():
    file = request.form.get('alarmSound')
    
    global alarmSound
    alarmSound = file

    print(f"modifided sound : {alarmSound}")
    
    return jsonify({'AlarmSound': file})

@app.route('/setVolume', methods = ['POST'])
def setAlarmVolume():
    file = float(request.form.get('alarmVolume'))
    
    file = file * 100
    
    global alarmVolume
    alarmVolume = file

    print(f"modifided volume : {alarmVolume}")

    return jsonify({'AlarmVolume': file})
    
@app.route('/setAlarmStrength', methods = ['POST'])
def setAlarmStrength():
    file = int(request.form.get('alarmStrength'))
    print(alarmStrengths[file])

    return jsonify({'AlarmVolume': file})

@app.route('/getNearestAlarm', methods=['GET'])
def get_nearest_alarm():
    global alarms
    if not alarms:  
        print('theres no alarms')
        return jsonify(None), 200

    now = datetime.datetime.now()
    nearest_alarm = min(alarms, key=lambda a: abs(a["time"] - now))
    print(nearest_alarm)
    return jsonify({
        "name": nearest_alarm["name"],
        "time": nearest_alarm["time"].isoformat(),  
    }), 200

@app.route('/getAlarms', methods=['GET'])
def getAlarms():
    recent_alarms = sorted(alarms, key=lambda x: x['time'])[:3]
    return jsonify({'alarms': recent_alarms}), 200

@app.route('/getSettings', methods=['GET'])
def getSettings():

    return jsonify({'alarmsound': alarmSound, 'alarmVolume' : alarmVolume}), 200

@app.route('/updateAlarm', methods=['POST'])
def updateAlarm():
    data = request.form
    print(data)
    name = data.get('name')
    old_time_str = data.get('old_time')  
    new_time_str = data.get('new_time')  
    new_name = data.get('new_name')      

    old_time = datetime.datetime.fromisoformat(old_time_str)
    new_time = datetime.datetime.fromisoformat(new_time_str)

    updated = False

    for alarm in alarms:
        if alarm['name'] == name and alarm['time'] == old_time:
            alarm['name'] = new_name
            alarm['time'] = new_time
            updated = True
            break

    if updated:
        print(f"Alarm updated: {name} at {old_time} -> {new_name} at {new_time}")
        return jsonify({'status': 'success', 'alarms': alarms}), 200
    else:
        print(f"No alarm found to update: {name} at {old_time}")
        return jsonify({'status': 'fail', 'message': 'Alarm not found'}), 404

if __name__ == '__main__':
    alarm_thread = threading.Thread(target=alarmCheck, daemon=True)
    alarm_thread.start()
    app.run(debug=True, host='172.30.1.36', port = 5200)
