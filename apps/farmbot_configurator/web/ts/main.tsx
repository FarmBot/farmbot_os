import * as React from "react";
import {
  RpcMessage,
  RpcNotification,
  RpcRequest,
  RpcResponse
} from "./json_rpc";
import { inject, observer } from "mobx-react";
import { MainState } from "./state";

interface MainProps {
  state: MainState
}

@observer
export class Main extends React.Component<MainProps, {}> {

  constructor(props: {}) {
    super(props);
  }

  componentDidMount() {
  }

  render() {
    return (
      <div>
        Count is: {this.props.state.counter || "MISSING>!>!>!"}
      </div>
    );
  }
}
