import * as React from "react";
import { observer } from "mobx-react";
import { observable, action } from "mobx";
import { MainState } from "./state";
import { ConfigFileNetIface } from "./interfaces";
import { TZSelect } from "./tz_select";
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
  hiddenresetwidget?: null | number;
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
      showPassword: false,
      hiddenresetwidget: 0
    };
  }

  @action
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
      mainState.uploadCreds(email, pass, server)
        .then((thing) => {
          console.log("uploaded web app credentials!");
        })
        .catch((thing) => {
          console.error("Error uploading web app credentials!")
        });
    } else {
      console.error("Email, Password, or Server is incomplete")
      return;
    }

    // upload config file.
    mainState.uploadConfigFile(fullFile)
      .then((_thing) => {
        console.log("uploaded config file. Going to try to log in");
        mainState.tryLogIn().catch((t) => {
          console.error("Something bad happend");
          console.dir(t);
        });
      })
      .catch((thing) => {
        console.error("Error uploading config file: ");
        console.dir(thing);
      });
  }

  // Handles the various input boxes.
  handleTZChange(optn: Select.Option) {
    let timezone = (optn.value || "").toString();
    console.log("Hi? " + timezone);
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
    if (Object.keys(config).length === 0) {
      return <div>
        <label>
          No Network devices detected!
        </label>
      </div>
    }
    return <div>
      {
        Object.keys(config)
          .map((ifaceName) => {
            let iface = config[ifaceName];
            switch (iface.type) {
              case "wireless":
                return <div>
                  <fieldset key={ifaceName}>
                    <label>
                      WiFi ( {ifaceName} )
                    </label>
                    <button type="button"
                      className="scan-button"
                      onClick={() => { this.props.mobx.scan(ifaceName) } }>
                      scan
                    </button>
                    <Select value="Select or type in a network name"
                      options={this.props.mobx.ssids.map(x => ({
                        value: x, label: x
                      }))} />
                    <span className="password-group">
                      <i onClick={this.showHidePassword.bind(this)}
                        className="fa fa-eye"></i>
                      <input type={passwordIsShown} />
                    </span>
                  </fieldset>
                </div>

              case "wired":
                return <fieldset>
                  <label>
                    Enable Ethernet ( {ifaceName} )
                  </label>
                  <input checked={iface.default === "dhcp"} type="checkbox" onChange={(event) => {
                    let c = event.currentTarget.checked;
                    if (c) {
                      // if the check is checked
                      this.props.mobx.updateInterface(ifaceName, { default: "dhcp" })
                    } else {
                      this.props.mobx.updateInterface(ifaceName, { default: false })
                    }
                  } } />
                </fieldset>
            }
          })
      }
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
      <h1 onClick={() => {
        this.setState({ hiddenresetwidget: this.state.hiddenresetwidget + 1 })
      } }>Configure your FarmBot</h1>

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
                {`What timezone your bot is in`}
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
        <div className="widget wifi" hidden={mainState.configuration.network == true}>
          <div className="widget-header">
            <h5>Network</h5>
            <i className="fa fa-question-circle widget-help-icon">
              <div className="widget-help-text">
                Bot configuration.
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

        {/* Reset Widget */}
        <div className="widget" hidden={this.state.hiddenresetwidget < 5}>
          <div className="widget-header">
            <h5>Factory Reset</h5>
            <i className="fa fa-question-circle widget-help-icon">
              <div className="widget-help-text">
                {`uh`}
              </div>
            </i>
          </div>
          <div className="widget-content">
            <fieldset>
              <label> Be careful here! </label>
              <button type="button" onClick={() => {
                this.props.mobx.factoryReset();
              } }> Factory Reset your bot! </button>
            </fieldset>
          </div>
        </div>

      </div>
    </div>
  }
}
