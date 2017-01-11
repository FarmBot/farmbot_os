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
        use: [
          'style-loader',
          'css-loader',
          'sass-loader'
        ]
      }, {
        test: /\.css$/,
        use: [
          'style-loader',
          'css-loader'
        ]
      }
      ,
      {
        test: /\.woff/,
        loader: "url-loader"
      }, {
        test: /\.woff2/,
        loader: "url-loader"
      }, {
        test: /\.ttf/,
        loader: "url-loader"
      }, {
        test: /\.eot/,
        loader: "file-loader"
      }, {
        test: /\.svg(\?v=\d+\.\d+\.\d+)?$/,
        loader: "url-loader"
      }
    ]
  }
}
