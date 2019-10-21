window.telemetry_http_get = function (url) {
  var jsonhttp = new XMLHttpRequest(); // a new request
  jsonhttp.open("GET", url, false);
  jsonhttp.send(null);
  return JSON.parse(jsonhttp.responseText);
}

window.chartColors = {
  red: 'rgb(255, 99, 132)',
  orange: 'rgb(255, 159, 64)',
  yellow: 'rgb(255, 205, 86)',
  green: 'rgb(75, 192, 192)',
  blue: 'rgb(54, 162, 235)',
  purple: 'rgb(153, 102, 255)',
  grey: 'rgb(201, 203, 207)'
};
var lineChartData = {
  labels: [],
  datasets: [
    {
      label: 'CPU Usage',
      borderColor: window.chartColors.red,
      backgroundColor: window.chartColors.red,
      fill: false,
      data: [],
      yAxisID: 'y-axis-1',
    }
  ]
};

window.onload = function () {
  var ctx = document.getElementById('canvas').getContext('2d');
  window.myLine = Chart.Line(ctx, {
    data: lineChartData,
    options: {
      responsive: true,
      hoverMode: 'index',
      stacked: false,
      title: {
        display: true,
        text: 'FarmBot OS Telemetry data'
      },
      scales: {
        yAxes: [
          {
            type: 'linear', // only linear but allow scale type registration. This allows extensions to exist solely for log scale for instance
            display: true,
            position: 'left',
            id: 'y-axis-1',
          }
        ],
      }
    }
  });

  window.telemetry_http_get("/api/telemetry/cpu_usage").forEach((cpu_usage_data) => {
    var timestamp = new Date(cpu_usage_data.timestamp);
    var dataentry = {
      t: timestamp,
      y: cpu_usage_data.value
    }
    window.myLine.data.labels.push(timestamp.toLocaleDateString());
    window.myLine.data.datasets.forEach((dataset) => {
      dataset.data.push(dataentry);
    });
    window.myLine.update();
  })
};
