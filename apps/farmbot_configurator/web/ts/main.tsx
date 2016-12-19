import * as React from "react";
import { observer } from "mobx-react";
import { MainState } from "./state";
import DevTools from 'mobx-react-devtools';


interface MainProps {
  state: MainState
}

@observer
export class Main extends React.Component<MainProps, {}> {

  constructor(props: {}) {
    super(props);
  }

  maybeSomething = function (state: MainState) {
    if (!state.connected) {
      return (<div> BOT WAS DISCONNECTED!!!</div>);
    } else {
      return (<div>BOT IS CONNECTED!</div>)
    }
  }

  render() {
    let state = this.props.state;

    return (
      <div>
        <DevTools />
        {this.maybeSomething(state)}
      </div>
    );
  }
}
