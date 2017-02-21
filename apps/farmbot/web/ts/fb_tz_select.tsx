import * as React from "react";
import * as _ from "lodash";

type OptionComponent = React.ComponentClass<DropDownItem>
  | React.StatelessComponent<DropDownItem>;

export interface DropDownItem {
  /** Value passed to the onClick cb and also determines the "chosen" option. */
  value: string;
  /** Name of the item shown in the list. */
  label: string;
  /** Component internal use only unless there's an edge case for it. */
  hidden?: boolean;
  /** To determine group-by styling on rendered lists. */
  heading?: boolean;
}

export interface SelectProps {
  /** The list of rendered options to select from. */
  dropDownItems: DropDownItem[];
  /** Determine whether the select list should always be open. */
  isOpen?: boolean;
  /** Custom JSX child rendered instead of a default item. */
  optionComponent?: OptionComponent;
  /** Optional className for `select`. */
  className?: string;
  /** Fires when option is selected. */
  onChange?: (newValue: DropDownItem) => void;
  /** Placeholder for the input. */
  placeholder?: string;
  /** Determines what label to show in the select box. */
  value: string | null;
  /** A property to prevent keyboards on mobile. */
  readOnly?: boolean;
}

export interface SelectState {
  label: string;
  isOpen: boolean;
  value: string | null;
}

export class FBSelect extends React.Component<SelectProps, Partial<SelectState>> {
  constructor() {
    super();
    this.state = {
      label: "",
      isOpen: false,
      value: null
    };
  }

  componentWillMount() {
    this.setState({
      isOpen: !!this.props.isOpen
    });
  }

  updateInput(e: React.SyntheticEvent<HTMLInputElement>) {
    this.setState({ label: e.currentTarget.value });
  }

  open() { this.setState({ isOpen: true }); }

  /** Closes the dropdown ONLY IF the developer has not set this.props.isOpen to
   * true, since that would indicate the developer wants it to always be open.
    */
  maybeClose = () => {
    this.setState({ isOpen: (this.props.isOpen || false) });
  }

  handleSelectOption = (option: DropDownItem) => {
    (this.props.onChange || (() => { }))(option);
    this.setState(option);
  }

  custItemList = (items: DropDownItem[]) => {
    if (this.props.optionComponent) {
      let Comp = this.props.optionComponent;
      return items
        .map((p, i) => {
          let key = this.generateKey(p, i);
          return <div onMouseDown={() => { this.handleSelectOption(p); }}
            key={key}
            readOnly={this.props.readOnly}>
            <Comp {...p}
            />
          </div>;
        });
    } else {
      throw new Error(`You called custItemList() when props.optionComponent was
      falsy. This should never happen.`);
    }
  }

  normlItemList = (items: DropDownItem[]) => {
    return items.map((option: DropDownItem, i) => {
      let { hidden, heading, label } = option;
      let classes = "select-result";
      if (hidden) { classes += " is-hidden"; }
      if (heading) { classes += " is-header"; }
      // TODO: Put this in a shared function when we finish debugging callbacks.
      let key = this.generateKey(option, i);
      return <div key={key}
        className={classes}
        onMouseDown={() => { this.handleSelectOption(option); }}>
        <label>{label}</label>
      </div>;
    });
  }

  // returns dropDownItems that match the user's search term.
  filterByInput = () => {
    return this.props.dropDownItems.filter((option: DropDownItem) => {
      let query = (this.state.label || "").toUpperCase();
      return (option.label.toUpperCase().indexOf(query) > -1);
    });
  }

  generateKey(p: DropDownItem, i: number) {
    let key = _.isUndefined(p.label) ? `${p.value}` : `${p.label}:@KEY${i}`;
    return key;
  }

  render() {
    let { className, optionComponent, placeholder} = this.props;
    let { isOpen } = this.state;
    // Dynamically chose custom vs. standard list item JSX based on options:
    let renderList = (optionComponent ? this.custItemList : this.normlItemList);
    return <div className={"select " + (className || "")}>
      <div className="select-search-container">
        <input type="text"
          readOnly={true}
          onChange={this.updateInput.bind(this)}
          onFocus={this.open.bind(this)}
          onBlur={this.maybeClose}
          placeholder={placeholder || "Search..."}
          value={this.state.label} />
      </div>
      <div className={"select-results-container is-open-" + !!isOpen}>
        {renderList(this.filterByInput())}
      </div>
    </div>;
  }
}
