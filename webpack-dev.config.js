const webpack = require('webpack');

const path = require('path');

module.exports = {
    mode: 'development',
    module: {
        rules: [
            {
                test: /\.elm$/,
                exclude: [/elm-stuff/, /node_modules/],
                use: [
                    {
                        loader: require.resolve("elm-asset-webpack-loader")
                    },
                    {
                        loader: 'elm-webpack-loader?verbose=true&warn=true',
                        options: {
                            optimize: false
                            , runtimeOptions: ['-A128M', '-H128M', '-n8m']
                            , forceWatch: true
                            , debug: true
                        }
                    },
                ]
            },
            {
                test: /\.(jpe?g|png|gif|svg|html)$/,
                exclude: /node_modules/,
                loader: 'file-loader?name=[name].[ext]',
                // options: {
                //     publicPath: function(path) {
                //         // transform `path` to a URL that the web server can understand and serve
                //         return "/public/" + path;
                //     }
                // }
            },
        ]
        , noParse: /\.elm$/
    },
    output: {
        path: path.resolve(__dirname, 'public'),
    },
    devServer: {
        inline: true,
        stats: {colors: true},
        historyApiFallback: true,
    },
    plugins: [new webpack.DefinePlugin({
        ENV: JSON.stringify('dev')
    })
    ],
};
