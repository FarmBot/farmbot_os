module.exports = {
  resolve: {
    extensions: [".js", ".ts", ".json", ".tsx", ".css", ".scss"]
  },
  entry: "./web/ts/entry.tsx",
  output: {
    path: "./priv/static/",
    filename: "bundle.js",
    publicPath: "/assets/",
  },
  module: {
    rules: [
      {
        test: /\.tsx?$/,
        loader: "ts-loader"
      },
      {
        test: /\.scss$/,
        exclude: /node_modules/,
        use: [
          'style-loader',
          'css-loader',
          'sass-loader'
        ]
      }]
  }
}
