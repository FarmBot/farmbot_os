import * as React from "react";
import { observer } from "mobx-react";
import { observable, action } from "mobx";
import { MainState } from "./state";
import { ConfigFileNetIface } from "./interfaces";
import { TZSelect } from "./tz_select";
import { STUB } from "./just_a_stub";
import * as Select from "react-select";
import "../../node_modules/roboto-font/css/fonts.css";
import "../../node_modules/font-awesome/css/font-awesome.css";

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
  showPassword?: boolean;
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
      showPassword: false
    };
  }

  handleSubmit(event: React.SyntheticEvent<HTMLFormElement>) {
    event.preventDefault();
    let mainState = this.props.mobx;
    let fullFile = mainState.configuration;

    let email = this.state.email;
    let pass = this.state.pass;
    let server = this.state.server;
    let tz = this.state.timezone;

    if (tz) {
      fullFile.configuration.timezone = tz;
    } else {
      console.error("Timezone is invalid");
      return;
    }

    if (email && pass && server) {
      mainState.uploadCreds(email, pass, server);
    } else {
      console.error("Email, Password, or Server is incomplete")
      return;
    }

    // upload config file.
    mainState.uploadConfigFile(fullFile);
    mainState.tryLogIn();
  }

  // Handles the various input boxes.
  handleTZChange(optn: Select.Option) {
    let timezone = (optn.value || "").toString();
    console.log("Hi?" + timezone);
    this.setState({ timezone: timezone });
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
    let passwordIsShown = this.state.showPassword ? "text" : "password";

    return <div>
      <label htmlFor="network">
        Network Name/SSID
        </label>
      {
        Object.keys(config)
          .map((ifaceName) => {
            if (ifaceName.includes("wlan")) { // For first pass, we'll fix later
              let iface = config[ifaceName];
              // Wireless interfaces need two input boxes
              return <div>
                <fieldset key={ifaceName}>
                  <Select value="Select or type in a network name"
                    options={this.props.mobx.ssids.map(x => ({
                      value: x, label: x
                    }))} />
                  <span className="password-group">
                    <i onClick={this.showHidePassword.bind(this)}
                      className="fa fa-eye"></i>
                    <input type={passwordIsShown} />
                  </span>
                  <button type="button"
                    className="scan-button"
                    onClick={() => { this.props.mobx.scan(ifaceName) } }>
                    Scan
                  </button>
                </fieldset>
              </div>
            }
          })
      }

      <fieldset>
        {
          /** TODO: Make this toggleable and rely on 
           * state to determine checked-ness.
           */
        }
        {
          /**
           * <button type="button"
           * onClick={() => {
           * // Enable this interface.
           * this.props.mobx.updateInterface(ifaceName,
           *   { default: "dhcp" });
           * } }>
           * Enable {ifaceName}
           * </button>
           * 
           */
        }
        <label htmlFor="ethernet">Ethernet?</label>
        <input type="checkbox" id="ethernet" />
      </fieldset>
    </div>
  }

  showHideUrl() {
    this.setState({ urlIsOpen: !this.state.urlIsOpen });
  }

  showHidePassword() {
    this.setState({ showPassword: !this.state.showPassword });
  }

  render() {
    let mainState = this.props.mobx;
    let icon = this.state.urlIsOpen ? "minus" : "plus";

    return <div className="container">
      <h1>Configure your FarmBot</h1>

      <h2 hidden={mainState.connected}>Trouble connecting to bot...</h2>

      {/* Only display if the bot is connected */}
      <div hidden={!mainState.connected} className={`col-md-offset-3 col-md-6
        col-sm-8 col-sm-offset-2 col-xs-12`}>

        {/* Timezone Widget */}
        <div className="widget timezone">
          <div className="widget-header">
            <h5>Location</h5>
            <i className="fa fa-question-circle widget-help-icon">
              <div className="widget-help-text">
                {`Log messages from your bot`}
              </div>
            </i>
          </div>
          <div className="widget-content">
            <fieldset>
              <label htmlFor="timezone">Timezone</label>
              <TZSelect callback={this.handleTZChange}
                current={this.props.mobx.configuration
                  .configuration.timezone} />
            </fieldset>
          </div>
        </div>

        {/* Wifi Widget */}
        <div className="widget wifi">
          <div className="widget-header">
            <h5>Wifi</h5>
            <i className="fa fa-question-circle widget-help-icon">
              <div className="widget-help-text">
                Bot configuration.
              </div>
            </i>
          </div>
          <div className="widget-content">
            {this.buildNetworkConfig(mainState.configuration.network ? mainState
              .configuration.network.interfaces : STUB)}
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

              <fieldset>
                <label htmlFor="password">
                  Password
                </label>
                <input type="password"
                  onChange={this.handlePassChange} />
              </fieldset>

              {this.state.urlIsOpen && (
                <fieldset>
                  <label htmlFor="url">
                    Server:
                </label>
                  <input type="url" id="url"
                    onChange={this.handleServerChange} />
                </fieldset>
              )}
            </div>
          </div>
          {/* Submit our web app credentials, and config file. */}
          <button type="submit">Save Configuration</button>
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
          <div className="widget-content">
            {this.props.mobx.logs[this.props.mobx.logs.length - 1].message}
          </div>
        </div>
      </div>
    </div>
  }
}
