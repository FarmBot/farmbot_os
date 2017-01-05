import * as React from "react";
import { observer } from "mobx-react";
import { observable, action } from "mobx";
import { MainState, NetworkInterface } from "./state";

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
    let mainState = this.props.state
    let config = mainState.configuration.configuration;
    config.timezone = this.state.timezone || "oops";

    // upload config file.
    // mainState.uploadConfigFile(this.props.ws);

    // set credentials
    // mainState.uploadAppCredentials({
    //   email: this.state.email || "oops",
    //   pass: this.state.pass || "oops",
    //   server: this.state.server || "oops"
    // }, this.props.ws);

    // try to log in
    // this.props.state.tryLogIn(this.props.ws);
    console.dir(this.state);
  }

  handleTZChange(event: any) {
    this.setState({ timezone: (event.target.value) });
  }
  handleEmailChange(event: any) {
    this.setState({ email: (event.target.value) });
  }
  handlePassChange(event: any) {
    this.setState({ pass: (event.target.value) });
  }
  handleServerChange(event: any) {
    this.setState({ server: (event.target.value) });
  }

  render() {
    let mainState = this.props.state;

    return <div className="container">
      <h1>Configure your FarmBot</h1>

      <h1 hidden={mainState.connected}> YOUR FARMBOT IS BROKEN!@!!!! </h1>


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
            X: <input readOnly={true} value={this.props.state.botStatus.location[0]} />
            Y: <input readOnly={true} value={this.props.state.botStatus.location[1]} />
            Z: <input readOnly={true} value={this.props.state.botStatus.location[2]} />
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
              <fieldset>
                <label htmlFor="timezone">
                  TimeZone
                </label>
                <input
                  id="timezone"
                  value={this.state.timezone ||
                    mainState.configuration.configuration.timezone
                    || "America/Los_Angeles"}
                  onChange={this.handleTZChange} />
              </fieldset>
              <fieldset>
                <label>
                  Network
                </label>
              </fieldset>
            </div>
          </div>

          {/* App */}
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
              <fieldset>
                <label htmlFor="email">
                  Email
                </label>
                <input type="email" id="email"
                  value={this.state.email || "admin@admin.com"}
                  onChange={this.handleEmailChange} />
              </fieldset>
              <fieldset>
                <label htmlFor="password">
                  Password
                </label>
                <input type="password" id="password"
                  value={this.state.pass || "password123"}
                  onChange={this.handlePassChange} />
              </fieldset>
              <fieldset>
                <label htmlFor="url">
                  Server:
                </label>
                <input type="url" id="url"
                  value={this.state.server
                    || mainState.configuration.authorization.server
                    || "http://192.168.29.167:3000"}
                  onChange={this.handleServerChange} />
              </fieldset>
              <button onClick={() => { } }>Submit Credentials</button>
              <button type="submit">Log In</button>
            </div>
          </div>
        </form>
      </div>
    </div>
  }
}
