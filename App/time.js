const READY = 1;
const START = 2;

var current_state = READY;

document.addEventListener("DOMContentLoaded", () => {
    const time_hour = document.getElementsByClassName("time-hour")[0];
    const time_minute = document.getElementsByClassName("time-minute")[0];
    const date_week = document.getElementsByClassName("week")[0];
    const date_ymd  = document.getElementsByClassName("ymd")[0];

    function updateClockAndCalendar() {
        const now = new Date();
        
        const hours = now.getHours().toString().padStart(2, '0');
        const minutes = now.getMinutes().toString().padStart(2, '0');
        const seconds = now.getSeconds().toString().padStart(2, '0');
        // clock.innerText = `${hours}:${minutes}`;
        time_hour.innerText = `${hours}`;
        time_minute.innerText = `${minutes}`
        
        const year = now.getFullYear();
        const month = (now.getMonth() + 1).toString().padStart(2, '0');
        const date = now.getDate().toString().padStart(2, '0');
        
        const daysOfWeek = ['일요일', '월요일', '화요일', '수요일', '목요일', '금요일', '토요일'];
        const dayOfWeek = daysOfWeek[now.getDay()];

        date_ymd.innerText = `${year}.${month}.${date}`;
        date_week.innerText = `${dayOfWeek}`;
    }

    updateClockAndCalendar();
    setInterval(updateClockAndCalendar, 1000);
});


var current_state = "READY"; // READY 또는 START 상태
var startTime = null; // START로 변환된 시간을 저장

document.addEventListener("keydown", function(event) {
    if (event.key === "Enter") {
        handleToggle();
    }
});

// 클릭 이벤트 추가
document.addEventListener("click", function() {
    handleToggle();
});

function handleToggle() {
    if (current_state == "READY") {
        toggleToStart();
    } else if (current_state == "START") {
        const now = new Date();
        const elapsedMinutes = Math.floor((now - startTime) / 1000 / 60); // 경과 시간(분)
        if (elapsedMinutes >= 10) {
            toggleToReady();
        } 
    }
}

function toggleToStart() {
    document.querySelector(".date-time").classList.add("shrink-date-time");
    document.querySelector(".date").classList.add("shrink-and-move-date");
    document.querySelector(".time").classList.add("shrink-and-move-time");
    document.querySelector(".stop-icon").classList.add("hidden");

    var extraContent = document.querySelector(".alarm-setting");

    if (extraContent.classList.contains("hidden")) {  
        extraContent.classList.remove("hidden");
        setTimeout(() => {
            extraContent.classList.add("visible");
        }, 5);
    }

    current_state = "START";
    startTime = new Date(); // START로 변환된 시간 저장
}

function toggleToReady() {
    document.querySelector(".date-time").classList.remove("shrink-date-time");
    document.querySelector(".date").classList.remove("shrink-and-move-date");
    document.querySelector(".time").classList.remove("shrink-and-move-time");
    document.querySelector(".stop-icon").classList.remove("hidden");

    var extraContent = document.querySelector(".alarm-setting");

    if (extraContent.classList.contains("visible")) {
        extraContent.classList.remove("visible");
        setTimeout(() => {
            extraContent.classList.add("hidden");
        }, 5);
    }

    current_state = "READY";
    startTime = null; // READY 상태로 전환되면 시간 초기화
}



$(document).ready(function () {
    // 새로운 알람 설정 버튼 클릭 시
    $('.select-box-2').on('click', function () {
        $('.overlay').removeClass('hidden').fadeIn();
        $('.alarm-setting-form').removeClass('hidden').fadeIn();
    });

    // 취소 버튼 클릭 시
    $('#cancel-button').on('click', function () {
        $('.overlay').fadeOut();
        $('.alarm-setting-form').fadeOut();
    });

    // 폼 제출 시 서버로 데이터 전송
    $('#alarm-form').on('submit', function (event) {
        event.preventDefault(); // 기본 동작 방지

        const alarmName = $('#alarm-name').val();
        const alarmDate = $('#alarm-date').val();
        const alarmTime = $('#alarm-time').val();

        const fullDateTime = `${alarmDate}T${alarmTime}`;
    
        $.ajax({
            url: 'http://172.30.1.36:5200/addAlarm',
            method: 'POST',
            contentType: 'application/x-www-form-urlencoded',
            data: {
                name : alarmName,
                time : fullDateTime
            },
            success: function (response) {
                alert('알람이 저장되었습니다!');
                $('.overlay').fadeOut();
                $('.alarm-setting-form').fadeOut();
                console.log('서버 응답:', response);
            },
            error: function () {
                alert('알람 저장에 실패했습니다.');
            },
        });
    });
    
});

function fetchAlarms() {
    $.ajax({
        url: 'http://172.30.1.36:5200/getAlarms', 
        method: 'GET',
        success: function (response) {
            updateAlarmUI(response.alarms); 
        },
        error: function (xhr, status, error) {
            console.error('알람 가져오기 실패:', status, error);
        },
    });
}

function fetchSettings() {
    $.ajax({
        url: 'http://172.30.1.36:5200/getSettings', 
        method: 'GET',
        success: function (response) {
            updateAlarmUI(response.alarms); 
        },
        error: function (xhr, status, error) {
            console.error('알람 가져오기 실패:', status, error);
        },
    });
}

function updateAlarmUI(alarms) {
    const alarmList = $('.alarm-list');
    alarmList.empty();

    alarms.slice(0, 3).forEach((alarm, index) => {
        const newTime = new Date(alarm.time);
        newTime.setHours(newTime.getHours() - 9); 

        alarms[index].time = newTime;

        const alarmContent = alarm.name || "알람 내용 없음";

        const alarmHTML = `
            <div class="alarm${index + 1}" style="margin-top: 30px;">
                <span style="font-size: 0.6rem; font-weight: 200;">${newTime.toLocaleDateString()}</span>
                
                <p style=" font-size: 1rem; font-weight: 300;">${alarmContent}</p>
                <span style="font-size: 1.0rem; font-weight: 150;">${newTime.toLocaleDateString('ko-KR', { weekday: 'long' })}</span>
                <span style="font-size: 1.0rem; font-weight: 150;">${newTime.toLocaleTimeString([], { hour: '2-digit', minute: '2-digit', hour12: false })}</span>
                
            </div>
        `;
        alarmList.append(alarmHTML);
    });
}


$(document).ready(function () {
    // "알람 내용 변경" 버튼 클릭 시 폼과 오버레이 표시
    $(".select-box-3").click(function () {
        $(".overlay").removeClass("hidden");
        $(".alarm-edit-form").removeClass("hidden");
        loadAlarmData(); // 서버에서 알람 데이터를 불러옴
    });

    // 오버레이를 클릭하면 폼 닫기
    $(".overlay").click(function () {
        closeEditAlarmForm();
    });
});

function closeEditAlarmForm() {
    $(".overlay").addClass("hidden");
    $(".alarm-edit-form").addClass("hidden");
}

function loadAlarmData() {
    // 서버에서 알람 데이터 가져오기
    $.get('http://172.30.1.36:5200/getAlarms', function (data) {
        const alarmSelect = $("#alarm-select");
        alarmSelect.empty();
        data.alarms.forEach(alarm => {
            alarmSelect.append(
                `<option value="${alarm.name}" data-time="${alarm.time}">
                    ${alarm.name} (${new Date(alarm.time).toLocaleString()})
                </option>`
            );
        });
    });
}


function saveEditedAlarm() {
    const selectedOption = $("#alarm-select").find(":selected");
    let oldTime = selectedOption.data("time"); // 기존 시간
    const name = selectedOption.val(); // 기존 이름
    const newName = $("#edit-alarm-name").val(); // 수정된 이름
    const newTime = $("#edit-alarm-time").val(); // 수정된 시간
    
    oldTime = new Date(oldTime).toISOString();

    const alarmData = {
        name: name,
        old_time: oldTime,
        new_time: newTime,
        new_name: newName
    };

    // 서버로 수정된 알람 데이터 전송
    $.ajax({
        url: 'http://172.30.1.36:5200/updateAlarm',
        method: 'POST',
        contentType: 'application/x-www-form-urlencoded',
        data: alarmData,
        success: function () {
            alert("알람이 수정되었습니다.");
            closeEditAlarmForm();
        },
        error: function () {
            alert("알람 수정에 실패했습니다.");
        }
    });
}

function getState() {
    $.ajax({
        url: 'http://172.30.1.3:5200/getState', 
        method: 'GET',
        success: function (response) {
            if(response.state == 'on'){
                $('button').prop('disabled', true);  

                $('.centered-button').prop('disabled', false);  

                $('.centered-button').removeClass('hidden'); 
            }else if(response.state == 'off'){
                $('button').prop('disabled', false);  

                $('.centered-button').prop('disabled', true);  

                $('.centered-button').addClass('hidden'); 
            }
        },
        error: function (xhr, status, error) {
            console.error('상태 가져오기 실패:', status, error);
        },
    });
}

function changeState() {
    $.ajax({
        url: 'http://172.30.1.36:5200/offAlarm', 
        method: 'POST',
        success: function(response) {
            console.log("상태 변경 요청 성공", response);
        },
        error: function(xhr, status, error) {
            console.log("상태 변경 요청 실패", error);
        }
    });
}


setInterval(getState, 1000);
setInterval(fetchAlarms, 1000);
fetchAlarms(); // 페이지 로드 시 즉시 실행
