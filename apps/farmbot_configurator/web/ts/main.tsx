import * as React from "react";
import { observer } from "mobx-react";
import { observable, action } from "mobx";
import { MainState } from "./state";
import { ConfigFileNetIface } from "./interfaces";

interface MainProps {
  state: MainState;
  ws: WebSocket;
}

interface FormState {
  timezone?: null | string;
  email?: null | string;
  pass?: null | string;
  server?: null | string;
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
    this.state = { timezone: null, email: null, pass: null, server: null };
  }

  @action
  handleSubmit(event: React.SyntheticEvent<HTMLFormElement>) {
    event.preventDefault();
    // alert("You bot is going to go offline!!!");
    let mainState = this.props.state;
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
    mainState.tryLogIn;
  }

  // Handles the various input boxes.
  handleTZChange(event: any) {
    this.setState({ timezone: (event.target.value || "") });
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

  @action
  buildNetworkConfig(config: { [name: string]: ConfigFileNetIface }) {
    let that = this;
    let blah = that.props.state.configuration.network;
    return <fieldset>
      <label htmlFor="network">
        Network
        </label>
      {
        Object.keys(config)
          .map((ifaceName) => {
            let iface = config[ifaceName];
            switch (iface.type) {
              // Wireless interfaces need two input boxes
              case "wireless":
                return <fieldset key={ifaceName}>
                  <label htmlFor={ifaceName}>
                    {ifaceName}
                  </label>
                  <button type="button"
                    onClick={() => { this.props.state.scan(ifaceName) } }>
                    Scan for WiFi </button>
                  <input type="text" />
                  <input type="text" />

                </fieldset>;

              // wired interfaces just need a enabled/disabled button
              case "wired":
                return <fieldset key={ifaceName}>
                  <label htmlFor={ifaceName}>
                    {ifaceName}
                  </label>
                  <button type="button"
                    onClick={() => {
                      // Enable this interface.
                      iface.default = "dhcp";
                      this.props.state.addInterface(ifaceName, iface);
                    } }>
                    Enable {ifaceName}
                  </button>
                </fieldset>;
            }
          })
      }
    </fieldset>

  }
}

render() {
  let mainState = this.props.state;

  return <div className="container">
    <h1>Configure your FarmBot</h1>

    <h1 hidden={mainState.connected}> Good Luck!! </h1>


    {/* Only display if the bot is connected */}
    <div hidden={!mainState.connected} className={`col-md-offset-3 col-md-6 
        col-sm-8 col-sm-offset-2`}>

      <div className="widget">

        <div className="widget-header">
          <h5> Logs </h5>
          <i className="fa fa-question-circle widget-help-icon">
            <div className="widget-help-text">
              {`Log messages from your bot`}
            </div>
          </i>
        </div>

        <div className="widget-content">
          {this.props.state.logs[this.props.state.logs.length - 1].message}
        </div>
      </div>

      <div className="widget">

        <div className="widget-header">
          <h5> Location </h5>
          <i className="fa fa-question-circle widget-help-icon">
            <div className="widget-help-text">
              {`Current Location of your bot`}
            </div>
          </i>
        </div>

        <div className="widget-content">
          X: <input readOnly={true}
            value={mainState.botStatus.location[0]} />
          Y: <input readOnly={true}
            value={mainState.botStatus.location[1]} />
          Z: <input readOnly={true}
            value={mainState.botStatus.location[2]} />
        </div>
      </div>

      <form onSubmit={this.handleSubmit}>

        {/* Bot */}
        <div className="widget">
          <div className="widget-header">
            <h5>Bot</h5>
            <i className="fa fa-question-circle widget-help-icon">
              <div className="widget-help-text">
                {`Bot configuration.`}
              </div>
            </i>
          </div>
          <div className="widget-content">
            {/* timezone */}
            <fieldset>
              <label htmlFor="timezone">
                TimeZone
                </label>
              <input
                id="timezone"
                onChange={this.handleTZChange} />
            </fieldset>

            {mainState.configuration.network ? this.buildNetworkConfig(mainState.configuration.network.interfaces) : <div></div>}

          </div>
        </div>

        {/* App */}
        <div className="widget">
          <div className="widget-header">
            <h5>Web App</h5>
            <i className="fa fa-question-circle widget-help-icon">
              <div className="widget-help-text">
                {`Farmbot Application Configuration`}
              </div>
            </i>
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

            <fieldset>
              <label htmlFor="url">
                Server:
                </label>
              <input type="url" id="url"
                onChange={this.handleServerChange} />
            </fieldset>

            {/* Submit our web app credentials, and config file. */}
            <button type="submit">Try to Log In</button>

          </div>
        </div>
      </form>
    </div>
  </div>
}
}
