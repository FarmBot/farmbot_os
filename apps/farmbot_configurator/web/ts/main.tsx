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
    mainState.uploadConfigFile(this.props.ws);

    // set credentials
    mainState.uploadAppCredentials({
      email: this.state.email || "oops",
      pass: this.state.pass || "oops",
      server: this.state.server || "oops"
    }, this.props.ws);

    // try to log in
    this.props.state.tryLogIn(this.props.ws);
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
    return (
      <div>
        {/* why are comments like this */}
        <div hidden={mainState.connected}>
          <h1> YOUR FARMBOT IS BROKEN!@!!!! </h1>
        </div>

        {/* Only display this div if the bot is connected */}
        <div hidden={!mainState.connected}>
          <div>

            <form onSubmit={this.handleSubmit}>
              {/* Bot Config*/}
              <h2> Bot Configuration </h2>
              <p>
                TimeZone: <input
                  value={this.state.timezone || mainState.configuration.configuration.timezone
                    || "America/Los_Angeles"}
                  onChange={this.handleTZChange} />
              </p>

              {/* Network Config*/}
              <h2> Network Configuration </h2>
              <p>
                <input type="button" onClick={
                  () => {
                    this.props.state.deleteMe();
                  }
                } value="Use Ethernet" />
              </p>

              {/* App Config*/}
              <h2> Web App Configuration </h2>
              <p>
                Email:
                <input type="email"
                  value={this.state.email || "admin@admin.com"}
                  onChange={this.handleEmailChange} />
              </p>
              <p>
                Password:
                <input type="password"
                  value={this.state.pass || "password123"}
                  onChange={this.handlePassChange} />
              </p>
              <p>
                Server:
                <input type="url"
                  value={this.state.server
                    || mainState.configuration.authorization.server
                    || "http://192.168.29.167:3000"}
                  onChange={this.handleServerChange} />
              </p>
              <input onClick={() => {
                mainState.uploadAppCredentials({
                  email: this.state.email || "oops",
                  pass: this.state.pass || "oops",
                  server: this.state.server || "oops"
                }, this.props.ws)
              }} type="button" value="submit web app credentials"/>

              {/*  Log in button*/}
              <input type="submit" value="Log In" />
            </form>

            {/* not quite as good as "ticker" */}
            <h4> Bot Logs </h4>
            <ul>
            {
              mainState.logs.map((el,index) => {
                el
              })
            }
            </ul>

          </div>
        </div>
      </div>
    );
  }
}
