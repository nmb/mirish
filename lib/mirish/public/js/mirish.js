function deleteRide(uuid) {
  var url = '/rides/' + uuid;
  if(confirm("Delete ride and all content?")){
    fetch(url,
        {
          method: 'delete',
          credentials: 'same-origin'
        }).then(function(response){
      document.getElementById(uuid).remove();
    }, function(error){
      alert(error);
    });
  }
};

function claimSeat(uuid, seatid, name) {
  var url = '/rides/' + uuid + '/' + seatid + '?name=' + name;
    fetch(url,
        {
          method: 'post',
          credentials: 'same-origin'
        }).then(function(response){
    }, function(error){
      console.log(error);
    });
    return false;
};

function postMessage(msg) {
  var url = window.location.href+ '?message=' + msg;
  document.getElementById('msgform').reset();
    fetch(url,
        {
          method: 'post',
          credentials: 'same-origin'
        }).then(function(response){
    }, function(error){
      console.log(error);
    });
  return false;
};

function updateSeat(seatid, name) {
  var div = document.getElementById(seatid);
  while (div.firstChild) {
        div.removeChild(div.firstChild);
  }
  var new_element = document.createElement('span');
  new_element.innerHTML = name;
  div.appendChild(new_element);
};

function notify(msg) {
  // check if the browser supports notifications
  if ("Notification" in window) {
    let noteString = "New message:" + msg;
    // check whether notification permissions have already been granted
    if (Notification.permission === "granted") {
      // if it's okay, create a notification
      navigator.serviceWorker.getRegistration().then(function(reg) {
        reg.showNotification(noteString);
      });
    }
    // otherwise ask the user for permission
    else if (Notification.permission !== "denied") {
      Notification.requestPermission().then(function (permission) {
        // if the user accepts, create a notification
        if (permission === "granted") {
          navigator.serviceWorker.getRegistration().then(function(reg) {
            reg.showNotification(noteString);
          });
        }
      });
    }
  }
};

function addMessage(date, msg, sendNotification) {
  var div = document.getElementById("messages");
  // make copy of message template
  var new_element = document.getElementById('msgtemplate').cloneNode(true);
  new_element.getElementsByClassName("msgheader")[0].innerHTML = date;
  new_element.getElementsByClassName("msgbody")[0].innerHTML = msg;
  new_element.style = "";
  new_element.id = "";
  div.insertBefore(new_element, div.firstChild);
  if(sendNotification) {
    notify(msg);
  }
};

