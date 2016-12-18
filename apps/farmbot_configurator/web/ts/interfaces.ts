export interface GlobalState {
    statusBox: StatusBoxProps;
    ws: WebSocket;
}

export interface StatusBoxProps {
    message: string;
}