let logger_table;
let thead;

window.onload = function() {
  logger_table = document.getElementById("logger_table"); 
}

const socket = new WebSocket("ws://" + location.host + "/logger_socket");
socket.onopen = function () {
  console.log("connected");
}

let add_value_to_row = function(row, value) {
  var cell = row.insertCell();
  var text = document.createTextNode(value); 
  cell.appendChild(text);
}

socket.onmessage = function (event) {
  let payload = JSON.parse(event.data);
  console.log(payload);
  let row = logger_table.insertRow();
  add_value_to_row(row, payload.level);
  add_value_to_row(row, payload.message);
  add_value_to_row(row, new Date(payload.datetime));
  add_value_to_row(row, payload.metadata.file + ":" + payload.metadata.line);
  add_value_to_row(row, payload.metadata.module);
  add_value_to_row(row, payload.metadata.function);
}