import * as React from "react";
import {
  RpcMessage,
  RpcNotification,
  RpcRequest,
  RpcResponse
} from "./json_rpc";
import { inject, observer } from "mobx-react";
import { MainProps } from "./state";

@inject("store") @observer
export class Main extends React.Component<MainProps, {}> {

  constructor(props: {}) {
    super(props);

  }

  componentDidMount() {
  }

  render() {
    return (
      <div>
        {this.props}
      </div>
    );
  }
}
