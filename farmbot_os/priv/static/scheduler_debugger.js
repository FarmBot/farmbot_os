let scheduler_table;
let thead;

window.onload = function() {
  scheduler_table = document.getElementById("scheduler_table"); 
  thead = scheduler_table.createTHead();
  let row = thead.insertRow();

  var th = document.createElement("th");
  var text = document.createTextNode("Data");
  th.appendChild(text);
  row.appendChild(th);

  var th = document.createElement("th");
  var text = document.createTextNode("Scheduled at");
  th.appendChild(text);
  row.appendChild(th);
}

const socket = new WebSocket("ws://" + location.host + "/scheduler_socket");
socket.onopen = function () {
  console.log("connected");
}

socket.onmessage = function (event) {
  let payload = JSON.parse(event.data);
  // console.log("unhandled payload:");
  // console.log(payload);
  let id = payload.id + " " + payload.at;
  if(document.getElementById(id)) {
    console.log(id + " already exists");
    return;
  }
  let row = scheduler_table.insertRow();
  row.id = id;

  var cell = row.insertCell();
  var text = document.createTextNode(payload.type + ": [ " + payload.data.name + " ]"); 
  cell.appendChild(text);

  var cell = row.insertCell();
  var text = document.createTextNode(new Date(payload.at));
  cell.appendChild(text);

}