# QrChk

**TODO: Add description**

## Installation

If [available in Hex](https://hex.pm/docs/publish), the package can be installed
by adding `qr_chk` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [{:qr_chk, "~> 0.1.0"}]
end
```

Documentation can be generated with [ExDoc](https://github.com/elixir-lang/ex_doc)
and published on [HexDocs](https://hexdocs.pm). Once published, the docs can
be found at [https://hexdocs.pm/qr_chk](https://hexdocs.pm/qr_chk).

Configuration
-------------
To configure lager's backends, you use an application variable (probably in
your app.config):

```elixir
config :qr_chk,
  phx_name: :im_webserver, #phoenix应用名称
  file_exp: 60 #二维码图片存在时长（s)
```

XXX.Endpoint Config
-------------
```elixir
  plug Plug.Static,    
    only: ~w(... qrchk)
```