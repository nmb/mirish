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
      //updateSeat(seatid, name)
      //document.getElementById(seatid).setAttribute("disabled", true);
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

