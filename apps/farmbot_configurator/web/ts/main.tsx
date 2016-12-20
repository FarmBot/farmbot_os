import * as React from "react";
import { observer } from "mobx-react";
import { MainState, NetworkInterface } from "./state";


interface MainProps {
  state: MainState;
  ws: WebSocket;
}

@observer
export class Main extends React.Component<MainProps, {}> {
  constructor(props: {}) {
    super(props);
  }

  render() {
    let state = this.props.state;

    return (
      <div>
        <h1> Configure your Farmbot! </h1>


        <div hidden={state.connected}>
          <h2> YOUR FARMBOT IS BROKEN!@!!!! </h2>
        </div>

        <div hidden={!state.connected}>
          <div>


            <div>
              <h3> Web App Configuration </h3>
            </div>



            <button onClick={() => {
              state.uploadConfigFile(this.props.ws);
            } }>
              Upload configuration!
            </button>

            <button onClick={() => {
              state.uploadAppCredentials({
                email: "admin@admin.com",
                pass: "password123",
                server: "http://192.168.29.167:3000"
              }, this.props.ws);
            } }>
              Upload Web Credentials
            </button>

            <div>
              <ul>
                {state.logs.map((el, index) => {
                  return <li key={index}>{el}</li>
                })}
              </ul>
            </div>
          </div>
        </div>
      </div>
    );
  }
}
