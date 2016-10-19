var phonecatApp = angular.module('phonecatApp', []);

// Define the `PhoneListController` controller on the `phonecatApp` module
phonecatApp.controller('PhoneListController', function PhoneListController($scope, $http) {
  $scope.ssids = [];
  $scope.should_use_ethernet = false;
  $scope.should_use_wifi = false;

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
    $scope.should_use_wifi = true;
    $scope.should_use_ethernet = false;
    document.getElementById("wifissid").value = ssid;
  };

  $scope.toggle_ethernet = function() {
    if(!$scope.should_use_ethernet){
      $scope.should_use_wifi = false;
      $scope.should_use_ethernet = true;
    } else {
      $scope.should_use_wifi = true;
      $scope.should_use_ethernet = false;
    }

  };

  $scope.submit = function(){
    email = document.getElementById("fbemail").value;
    password = document.getElementById("fbpwd").value;
    server = document.getElementById("fbserver").value;
    port = document.getElementById("fbport").value;
    realSrv = "http://" + server + ":" + port;

    json = {
      "email": email,
      "password": password,
      "server": realSrv
    };

    if($scope.should_use_ethernet){
      json["ethernet"] = true
    } else {
      ssid = document.getElementById("wifissid").value;
      psk = document.getElementById("wifipsk").value;
      json["wifi"] = {
        "ssid": ssid,
        "psk": psk
      }
    }

    if(email != ""){
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
