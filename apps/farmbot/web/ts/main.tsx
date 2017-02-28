import * as React from "react";
import { observer } from "mobx-react";
import { observable, action } from "mobx";
import { MainState } from "./state";
import { ConfigFileNetIface, IfaceType } from "./interfaces";
import { TZSelect } from "./tz_select";
import { AdvancedSettings } from "./advanced_settings";
import * as Select from "react-select";
import * as _ from "lodash";

interface MainProps {
  mobx: MainState;
  ws: WebSocket;
}

interface FormState {
  timezone?: null | string;
  email?: null | string;
  pass?: null | string;
  server?: null | string;
  urlIsOpen?: boolean;
  showWifiPassword?: boolean;
  showWebPassword?: boolean;
  logExpanded?: boolean;
  hiddenAdvancedWidget?: null | number;
  showCustomNetworkWidget?: null | boolean;
  ssidSelection?: { [name: string]: string };
  customInterface?: null | string;
  connecting?: boolean;
}

@observer
export class Main extends React.Component<MainProps, FormState> {
  constructor(props: MainProps) {
    super(props);
    this.handleSubmit = this.handleSubmit.bind(this);
    this.handleTZChange = this.handleTZChange.bind(this);
    this.handleEmailChange = this.handleEmailChange.bind(this);
    this.handlePassChange = this.handlePassChange.bind(this);
    this.handleServerChange = this.handleServerChange.bind(this);
    this.state = {
      timezone: null,
      email: null,
      pass: null,
      server: null,
      urlIsOpen: false,
      showWifiPassword: false,
      showWebPassword: false,
      logExpanded: false,
      hiddenAdvancedWidget: 0,
      showCustomNetworkWidget: false,
      ssidSelection: {},
      customInterface: null,
      connecting: false
    };
  }

  @action
  handleSubmit(event: React.SyntheticEvent<HTMLFormElement>) {
    event.preventDefault();
    let mainState = this.props.mobx;
    let fullFile = mainState.configuration;

    let email = this.state.email;
    let pass = this.state.pass;
    let server = this.state.server || fullFile.authorization.server;
    let tz = this.state.timezone || fullFile.configuration.timezone;
    console.log("server: " + server);
    console.log("timezone: " + tz);

    if (tz) {
      fullFile.configuration.timezone = tz;
    } else {
      console.error("Timezone is invalid");
      return;
    }

    if ((email && pass && server) && this.state.connecting != true) {
      // this.state.connecting = true;
      this.setState({ connecting: true });
      mainState.uploadCreds(email, pass, server)
        .then((thing) => {
          console.log("uploaded web app credentials!");
        })
        .catch((thing) => {
          console.error("Error uploading web app credentials!")
        });
    } else {
      console.error("Email, Password, or Server is incomplete or already connecting!")
      return;
    }

    // upload config file.
    mainState.uploadConfigFile(fullFile)
      .then((_thing) => {
        console.log("uploaded config file. Going to try to log in");
        mainState.tryLogIn().catch((t) => {
          console.error("Something bad happend");
          console.dir(t);
          mainState.setConnected(false);
        });
      })
      .catch((thing) => {
        console.error("Error uploading config file: ");
        console.dir(thing);
      });
  }

  // Handles the various input boxes.
  @action
  handleTZChange(optn: Select.Option) {
    let timezone = (optn.value || "").toString();
    console.log("Hi? " + timezone);
    this.setState({ timezone: timezone });

    // this is so we don't have to do null juggling from having too possible
    // places for this value to come from
    this.props.mobx.configuration.configuration.timezone = timezone;
  }
  handleEmailChange(event: any) {
    this.setState({ email: (event.target.value || "") });
  }
  handlePassChange(event: any) {
    this.setState({ pass: (event.target.value || "") });
  }
  handleServerChange(event: any) {
    this.setState({ server: (event.target.value || "") });
  }

  buildNetworkConfig(config: { [name: string]: ConfigFileNetIface }) {
    let wifiPasswordIsShown = this.state.showWifiPassword ? "text" : "password";
    let ssidArray = this.props.mobx.ssids.map((val) => { return { value: val, label: val } });
    let mobx = this.props.mobx;
    let that = this;
    let state = this.state;

    let getSsidValue = function (ifaceName: string) {
      let f = "couldn't find value";
      if (state.ssidSelection) {
        f = state.ssidSelection[ifaceName] || "no iface";
      } else {
        f = "no_selection";
      }
      return f;
    }

    let wirelessInputOrSelect = function (ifaceName: string, onChange: (value: string) => void) {
      let ssids = mobx.ssids;
      if (ssids.length === 0) {
        // the ssid list is empty. You should enter your own
        return <input placeholder="Enter a WiFi ssid or press SCAN"
          onChange={(event) => {
            onChange(event.currentTarget.value);
          }} />
      } else {
        return <Select
          value={getSsidValue(ifaceName)}
          options={ssidArray}
          onChange={(event: Select.Option) => {
            onChange((event.value || "oops").toString());
          }} />
      }
    }

    // im sorry
    let customInterfaceInputOrSelect = function (onChange: (value: string) => void) {
      // am i even aloud to do this?
      let blah = that.state.customInterface;
      let blahConfig: ConfigFileNetIface = { type: "wired", default: "dhcp" };

      let hidden = true;
      if ((that.state.hiddenAdvancedWidget as number) > 4 || that.state.showCustomNetworkWidget == true) {
        hidden = false;
      }

      // default to a regular input
      let userInputThing = <input onChange={(event) => {
        blah = event.currentTarget.value;
        onChange(event.currentTarget.value);
      }} />

      // if the list is not empty, display a selection of them
      if (mobx.possibleInterfaces.length !== 0) {
        userInputThing = <Select
          value={blah || undefined} // lol
          placeholder="select an interface"
          options={mobx.possibleInterfaces.map((x) => { return { value: x, label: x } })}
          onChange={(event: Select.Option) => {
            let blah1 = (event.value || "oops").toString();
            blah = blah1;
            onChange(blah1);
          }} />
      }

      // only show this widget if the state says so.
      return <div hidden={hidden}>
        <label>Custom Interface</label>
        {userInputThing}
        <fieldset>
          <label> Wireless </label>
          <input onChange={(event) => {
            // if the user ticks this box, change the config to wireless or not
            blahConfig.type = (event.currentTarget.checked ? "wireless" : "wired");
          }}
            defaultChecked={blahConfig.type == "wireless"}
            type="checkbox" />
        </fieldset>

        {/* Add the interface to the config file */}
        <button onClick={() => {
          if (blah) {
            console.log(blah);
            console.log(blahConfig);
            mobx.addInterface(blah, blahConfig);
            that.forceUpdate(); // what am i doing.
          }
        }}
          className="save-interface-button">
          Save interface
          </button>
      </div>;
    }

    if (Object.keys(config).length === 0) {
      return <div>
        <fieldset>
          <label>No Network devices detected!</label>
          {/* Scan button */}
          <button type="button"
            className="add-interface-button"
            onClick={() => {
              mobx.enumerateInterfaces();
              that.setState({ showCustomNetworkWidget: !that.state.showCustomNetworkWidget })
            }}>
            Add Custom Interface
          </button>
        </fieldset>
        {customInterfaceInputOrSelect((value) => {
          this.setState({ customInterface: value });
        })}
      </div>
    }
    return <div>
      {/* this widget is hidden unless the above button is ticked. */}
      {customInterfaceInputOrSelect((value) => {
        this.setState({ customInterface: value });
      })}
      {
        Object.keys(config)
          .map((ifaceName) => {
            let iface = config[ifaceName];
            switch (iface.type) {
              // if the interface is wireless display the
              // select box, and a password box
              case "wireless":
                return <div key={ifaceName}>
                  <fieldset className="password-group">
                    <label>
                      WiFi ( {ifaceName} )
                    </label>

                    {/* Scan button */}
                    <button type="button"
                      className="scan-button"
                      onClick={() => { this.props.mobx.scan(ifaceName) }}>
                      SCAN
                    </button>

                    {/*
                      If there are ssids in the list, display a select box,
                      if not display a raw input box
                    */}
                    {wirelessInputOrSelect(ifaceName, (value => {
                      // update it in local state
                      this.setState(
                        // this will overrite any other wireless ssid selections.
                        // will need to do a map.merge to avoid destroying any other selections
                        // if that situation ever occurs
                        {
                          ssidSelection: {
                            [ifaceName]: value
                          }
                        });
                      // update it in the config
                      mobx.updateInterface(ifaceName,
                        { type: "wireless", default: "dhcp", settings: { ssid: value } });
                    }))}

                    <i onClick={this.showHideWifiPassword.bind(this)}
                      className={"fa fa-eye " + wifiPasswordIsShown}></i>

                    <input type={wifiPasswordIsShown} onChange={(event) => {
                      this.props.mobx.updateInterface(ifaceName,
                        {
                          settings: {
                            psk: event.currentTarget.value,
                            key_mgmt: "WPA-PSK"
                          }
                        })
                    }} />
                  </fieldset>
                </div>

              case "wired":
                return <div key={ifaceName}>
                  <fieldset>
                    <label>
                      Enable Ethernet ( {ifaceName} )
                    </label>
                    <input defaultChecked={iface.default === "dhcp"}
                      type="checkbox" onChange={(event) => {
                        let c = event.currentTarget.checked;
                        if (c) {
                          // if the check is checked
                          this.props.mobx.updateInterface(ifaceName,
                            { default: "dhcp" })
                        } else {
                          this.props.mobx.updateInterface(ifaceName,
                            { default: false })
                        }
                      }} />
                  </fieldset>
                </div>
            }
          })
      }
    </div>
  }

  showHideUrl() {
    this.setState({ urlIsOpen: !this.state.urlIsOpen });
  }

  showHideWifiPassword() {
    this.setState({ showWifiPassword: !this.state.showWifiPassword });
  }

  showHideWebPassword() {
    this.setState({ showWebPassword: !this.state.showWebPassword });
  }

  toggleExpandedLog() {
    this.setState({ logExpanded: !this.state.logExpanded });
  }

  render() {
    let mainState = this.props.mobx;
    let webPasswordIsShown = this.state.showWebPassword ? "text" : "password";
    let icon = this.state.urlIsOpen ? "minus" : "cog";
    let header = this.state.connecting ? "Configuration is Complete!" : "Configure Your FarmBot";
    let text = this.state.connecting ? "FarmBot will now restart and attempt to connect to the web app. Login to your web app account to verify that FarmBot has connected. If it fails, the configurator will automatically restart and you can try again." : "Your web browser is having trouble connecting to the configurator. Are you using a modern updated browser? If so, your OS might be corrupted and need to be re-flashed";
    let logMessage = mainState.logs[mainState.logs.length - 1].message
    let finalMessage = (logMessage.length > 80 && !this.state.logExpanded) ?
      _.truncate(logMessage, { length: 80 }) : logMessage;
    let logIcon = this.state.logExpanded ? "minus" : "plus";

    let submitText = this.state.connecting ? "SUBMITTING CONFIGURATION!" : "SUBMIT CONFIGURATION";

    return <div className="container">
      <h1 onClick={() => {
        let val = (this.state.hiddenAdvancedWidget as number) + 1;
        this.setState({ hiddenAdvancedWidget: val });
        if (val > 4) {
          this.props.mobx.enumerateInterfaces();
        }
      }}>{header}</h1>

      <h2 hidden={mainState.connected}> {text} </h2>

      {/* Only display if the bot is connected */}
      <div hidden={!mainState.connected} className={`col-md-offset-3 col-md-6
        col-sm-8 col-sm-offset-2 col-xs-12`}>

        {/* Timezone Widget */}
        <div className="widget timezone">
          <div className="widget-header">
            <h5>Location</h5>
            <i className="fa fa-question-circle widget-help-icon">
              <div className="widget-help-text">
                {`What timezone your bot is in`}
              </div>
            </i>
          </div>
          <div className="widget-content">
            <fieldset>
              <label htmlFor="timezone">Timezone</label>
              <TZSelect
                callback={this.handleTZChange}
                current={this.props.mobx.configuration.configuration.timezone} />
            </fieldset>
          </div>
        </div>

        {/* Network Widget */}
        <div className="widget wifi" hidden={mainState.configuration.network == true}>
          <div className="widget-header">
            <h5>Network</h5>
            <i className="fa fa-question-circle widget-help-icon">
              <div className="widget-help-text">
                Bot Network Configuration
              </div>
            </i>
          </div>
          <div className="widget-content">
            {this.buildNetworkConfig(
              mainState.configuration.network ? mainState.configuration.network.interfaces : {})}
          </div>
        </div>

        {/* App Widget */}
        <form onSubmit={this.handleSubmit}>
          <div className="widget app">
            <div className="widget-header">
              <h5>Web App</h5>
              <i className="fa fa-question-circle widget-help-icon">
                <div className="widget-help-text">
                  Farmbot Application Configuration
                </div>
              </i>
              <i onClick={this.showHideUrl.bind(this)}
                className={`fa fa-${icon}`}></i>
            </div>
            <div className="widget-content">
              <fieldset>
                <label htmlFor="email">
                  Email
                </label>
                <input type="email" id="email"
                  onChange={this.handleEmailChange} />
              </fieldset>

              <fieldset className="password-group web">
                <label htmlFor="password">
                  Password
                </label>
                <input type={webPasswordIsShown}
                  onChange={this.handlePassChange} />
                <i onClick={this.showHideWebPassword.bind(this)}
                  className={"fa fa-eye " + webPasswordIsShown}></i>
              </fieldset>

              {this.state.urlIsOpen && (
                <fieldset>
                  <label htmlFor="url">
                    Server:
                </label>
                  <input type="url" id="url"
                    defaultValue={this.props.mobx.configuration.authorization.server}
                    onChange={this.handleServerChange} />
                </fieldset>
              )}
            </div>
          </div>
          {/* Submit our web app credentials, and config file. */}
          <button type="submit"> {submitText} </button>
        </form>

        {/* Logs Widget */}
        <div className="widget">
          <div className="widget-header">
            <h5>Logs</h5>
            <i className="fa fa-question-circle widget-help-icon">
              <div className="widget-help-text">
                {`Log messages from your bot`}
              </div>
            </i>
          </div>
          <div className="widget-content log-message">
            {finalMessage}
            <i className={`fa fa-${logIcon} expand-logs-icon 
            is-expanded-${this.state.logExpanded}`}
              onClick={this.toggleExpandedLog.bind(this)}></i>
          </div>
        </div>

        {/* Advanced Widget */}
        <div className="widget" hidden={(this.state.hiddenAdvancedWidget as number) < 5}>
          <div className="widget-header">
            <h5>Advanced Settings</h5>
            <i className="fa fa-question-circle widget-help-icon">
              <div className="widget-help-text">
                {`Various advanced settings`}
              </div>
            </i>
          </div>
          <div className="widget-content">
            <AdvancedSettings mobx={mainState} />
          </div>
        </div>

      </div>
    </div>
  }
}
