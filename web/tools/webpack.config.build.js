var UglifyJsPlugin = require('webpack-uglify-js-plugin');
var ExtractTextPlugin = require('extract-text-webpack-plugin');
var OptimizeCssAssetsPlugin = require('optimize-css-assets-webpack-plugin');
var webpack = require('webpack');
var resolve = require('path').resolve;

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
    new webpack.DefinePlugin({
      'process.env': {
        NODE_ENV: JSON.stringify('production')
      }
    }),

    new ExtractTextPlugin({
      filename: "/styles.css",
      disable: false,
      allChunks: true
    }),

    new OptimizeCssAssetsPlugin({
      assetNameRegExp: /\.css$/g,
      cssProcessor: require("cssnano"),
      cssProcessorOptions: { discardComments: { removeAll: true } },
      canPrint: true
    }),

    new UglifyJsPlugin({
      cacheFolder: "cache",
      compress: {
        warnings: true
      }
    })
  ],
  module: {
    rules: [
      { test: /\.tsx?$/, loader: "ts-loader" },
      { test: [/\.scss$/, /\.css$/], loader: ExtractTextPlugin.extract("css-loader!sass-loader") },
      { test: /\.woff/, loader: "url-loader" },
      { test: /\.woff2/, loader: "url-loader" },
      { test: /\.ttf/, loader: "url-loader" },
      { test: /\.eot/, loader: "file-loader" },
      { test: /\.svg(\?v=\d+\.\d+\.\d+)?$/, loader: "url-loader" }
    ]
  }
}
