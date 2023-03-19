const webpack = require('webpack');
const path = require('path');

module.exports = {
    mode: 'production',
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
                            optimize: true
                            , runtimeOptions: ['-A128M', '-H128M', '-n8m']
                            , forceWatch: true
                        }
                    }
                ]
            },
            {
                test: /\.html$/,
                exclude: /node_modules/,
                loader: 'file-loader?name=[name].[ext]'
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
            ENV: JSON.stringify('prod')
        })
    ],
};
