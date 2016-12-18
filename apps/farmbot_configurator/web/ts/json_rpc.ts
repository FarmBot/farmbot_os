export type RpcMessage = RpcNotification | RpcRequest | RpcResponse
/** just like a request but doesn't expect a response. */
export interface RpcNotification {
    method: string;
    params: any;
    id: string;
}
/** request a thing to happen and get info back as a response. */
export interface RpcRequest {
    method: string;
    params: any;
    id: null;
}
/** A response to a request. */
export interface RpcResponse {
    results: any;
    error: null | any;
    /** the id od the request that waranted this response. */
    id: string;
}