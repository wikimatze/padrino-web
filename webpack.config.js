const webpack = require('webpack');
const path = require('path');
const Clean = require('clean-webpack-plugin');
const ExtractTextPlugin = require('mini-css-extract-plugin');

module.exports = {
  devtool: 'source-map',

  entry: {
    main: [
      './assets/javascripts/all.js',
      './assets/stylesheets/all.css.scss',
    ],
  },

  output: {
    path: __dirname + '/.tmp/dist',
    filename: 'assets/javascripts/all.js',
  },

  module: {
    rules: [
      {
        test: /\.scss$/,
        use: [
                ExtractTextPlugin.loader, // creates style nodes from JS strings
                "css-loader", // translates CSS into CommonJS
                "sass-loader" // compiles Sass to CSS
            ]
      }
    ]
  },

  plugins: [
    new ExtractTextPlugin({filename: 'assets/stylesheets/all.css', allChunks: true}),
    new Clean(['.tmp']),
  ],

  mode: "none",
};
