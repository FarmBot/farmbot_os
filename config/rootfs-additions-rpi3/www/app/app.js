var phonecatApp = angular.module('phonecatApp', []);

// Define the `PhoneListController` controller on the `phonecatApp` module
phonecatApp.controller('PhoneListController', function PhoneListController($scope, $http) {
  $scope.ssids = [];

  // $scope.url = "http://" + location.host.split(":")[0] + ":4000";
  $scope.url = "http://192.168.24.1:4000";
  $http.get($scope.url + "/scan").then(function(resp){
    console.log(resp.data);
    $scope.ssids = resp.data;
  }).catch(function(error){
    console.log("not running on device?");
    $scope.ssids = [];
  })

  $scope.select_ssid = function(ssid){
    document.getElementById("wifissid").value = ssid;
  };

  $scope.submit = function(){

    ssid = document.getElementById("wifissid").value;
    psk = document.getElementById("wifipsk").value;
    email = document.getElementById("fbemail").value;
    password = document.getElementById("fbpwd").value;
    server = document.getElementById("fbserver").value;
    port = document.getElementById("fbport").value;

    realSrv = "http://" + server + ":" + port;
    if(ssid != ""){
      json = {
        "email": email,
        "password": password,
        "server": realSrv,
        "wifi":{
          "ssid": ssid,
          "psk": psk
        }
      };
      console.log(JSON.stringify(json));
      $http.post($scope.url + "/login", json).then(function(resp){
        console.log("Should never see this...");
      }).catch(function(error){
        console.log("will probably see this a lot...");
        console.log(JSON.stringify(error));
      });
    }
  };
});
