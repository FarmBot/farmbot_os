let resolve = require("path").resolve;
module.exports = {
  resolve: {
    alias: {
      // 'react': 'react-lite',
      // 'react-dom': 'react-lite'
    },
    extensions: [".js", ".ts", ".json", ".tsx", ".css", ".scss"]
  },
  entry: "./web/ts/entry.tsx",
  devtool: "source-map",
  output: {
    path: resolve("./priv/static/"),
    filename: "bundle.js",
    publicPath: "/",
  },
  plugins: [
  ],
  module: {
    rules: [
      { test: /\.tsx?$/, loader: "ts-loader" },
      { test: [/\.scss$/, /\.css$/], use: [
          'style-loader',
          'css-loader',
          'sass-loader'
        ] },
      { test: /\.woff/, loader: "url-loader" },
      { test: /\.woff2/, loader: "url-loader" },
      { test: /\.ttf/, loader: "url-loader" },
      { test: /\.eot/, loader: "file-loader" },
      { test: /\.svg(\?v=\d+\.\d+\.\d+)?$/, loader: "url-loader" }
    ]
  }
}
