import { RpcMessage, RpcRequest, RpcResponse, RpcNotification } from "./interfaces";

/** a rpc message but with a kind key of what it is.*/
type TaggedRpcMessage = TaggedRpcRequest
    | TaggedRpcResponse
    | TaggedRpcNotification
    | TaggedFailure;

/** a request but with a kind key */
interface TaggedRpcRequest {
    kind: "request";
    val: RpcRequest
}

/** a response but with a kind key */
interface TaggedRpcResponse {
    kind: "response";
    val: RpcResponse
}

/** a notification but with a kind key */
interface TaggedRpcNotification {
    kind: "notification";
    val: RpcNotification;
}

/** an rpc that could not be sorted. */
interface TaggedFailure {
    kind: "failure";
    val: any;
}

export function infer(mystery: any): TaggedRpcMessage {
    if (mystery.id && mystery.response) {
        return { kind: "response", val: mystery }
    }

    if (mystery.id) {
        return { kind: "request", val: mystery }
    }

    if (mystery.id === null) {
        return { kind: "notification", val: mystery }
    }

    return { kind: "failure", val: mystery }
}
