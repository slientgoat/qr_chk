defmodule QrChk do
  @moduledoc """
  Documentation for QrChk.
  """
  @file_exp (Application.get_env(:qr_chk, :file_exp) || 60)*1000

  @doc false
  def save_path() do
    phx_name = Application.get_env(:qr_chk, :phx_name) || :qr_chk
    appdir = Application.app_dir(phx_name)
    save_dir = "#{appdir}/priv/static/qrchk"
    File.exists?(save_dir) || File.mkdir_p!(save_dir)
    save_dir
  end

  @doc false
  def file_path(name),do: "#{save_path()}/#{name}.png"
  def file_url(name,url),do: "#{url}/qrchk/#{name}.png"

  @doc false
  def del_file(name), do: File.rm(file_path(name))

  @doc false
  def del_all() do
     File.rm_rf(save_path())
     File.exists?(save_path()) || File.mkdir_p!(save_path())
  end

  @doc """
  生成二维码url

  ## Examples

      iex> result = QrChk.gen_qr_url(%{appid: "appid1",uid: "1001"},"9Cf1mwejO0Vy7XK0wwhnNsLw/lRE68En","https://test.com","http://192.168.10.71:4002/openapi/api/get_login_url","1504257462")
      iex> case result do
      ...>   {:ok,url}->
      ...>     String.contains?(url,"https://test.com")
      ...>   {:error,msg}->
      ...>     is_binary(msg)
      ...> end
      true
  """
  @spec gen_qr_url(kvs::map,secret::binary,qr_url::binary,calback_url::binary,tz::integer|binary) :: {:ok,binary} | {:error,binary}
  def gen_qr_url(kvs,secret,qr_url,req_url\\"",tz \\ DateTime.to_unix(DateTime.utc_now)) do
    url = gen_sign_url(kvs,secret,req_url,tz)
    case get_req(url) do
      {true,data}->
        {filename,_bin} = gen_qr(data)
        {:ok,file_url(filename,qr_url)}
      {false,error} ->
        {:error,error}
    end
  end

  @doc """
  获取二维码url

  ## Examples

      iex> {:ok,url} = QrChk.get_qr_url(%{data: "token",tz: "1500874428"},"9Cf1mwejO0Vy7XK0wwhnNsLw/lRE68En","0a66c0d2c534b14b9c65551d0bba0214","http://192.168.10.71:4002/openapi/api/qrcode")
      iex> String.contains?(url,"http://192.168.10.71:4002/openapi/api/qrcode")
      true

  """
  @spec get_qr_url(kvs::map,secret::binary,sign::binary,qr_url::binary) :: {:ok,binary} | {:error,binary}
  def get_qr_url(kvs,secret,sign,qr_url) do
    case chk_sign(kvs,secret,sign) do
      true ->
        {filename,_bin} = gen_qr(kvs.data)
        {:ok,file_url(filename,qr_url)}
      false ->
        {:error,"sign is invaild"}
    end


  end

  defp gen_qr(data,_mode \\ nil) do
    qrcode = :qrcode.encode(data)
    image = :qrcode_demo.simple_png_encode(qrcode)
    filename = gen_secret(30)
    File.write!(file_path(filename), image)
    spawn(fn () ->
      Process.sleep(@file_exp)
      del_file(filename)
    end)
    {filename,image}
  end

  @doc """
  生成签名路径

  ## Examples

      iex> QrChk.gen_sign_url(%{appid: "appid1",uid: "1001"},"9Cf1mwejO0Vy7XK0wwhnNsLw/lRE68En","https://test.com/openapi","1504257462")
      "https://test.com/openapi?sign=193dbf674fda1ad98b85085a05ddbbee&appid=appid1&tz=1504257462&uid=1001"

  """
  @spec gen_sign_url(kvs::map,secret::binary,url::binary,tz::integer|binary) :: binary
  def gen_sign_url(kvs,secret,url\\"",tz \\ DateTime.to_unix(DateTime.utc_now)) do
    kvs = Map.put(kvs,:tz,tz)
    sign = sign(kvs,secret)
    str = Map.to_list(kvs) |> Enum.map(fn({k,v})-> "&#{k}=#{v}" end) |> Enum.join()
    "#{url}?sign=#{sign}#{str}"
  end


  @doc """
  验证签名

  ## Examples

      iex> QrChk.chk_sign(%{appid: "appid1",uid: "1001",tz: "1504257462"},"9Cf1mwejO0Vy7XK0wwhnNsLw/lRE68En","193dbf674fda1ad98b85085a05ddbbee")
      true

  """
  @spec chk_sign(map,binary,binary) :: boolean
  def chk_sign(kvs,secret,sign) do
    sign(kvs,secret) == sign
  end

  defp sign(kvs,secret) do
    [secret|Map.values(kvs)] |> Enum.join |> sign_md5()
  end

  @doc """
  获取指定长度的随机字符串
  """
  @spec gen_secret(integer) :: binary
  def gen_secret(size \\ 40),do: Regex.replace(~r/\=|\/|\+/ ,:crypto.strong_rand_bytes(size) |> Base.encode64,to_string(Enum.random(0..9))) |> binary_part(0, size)

  @doc """
    md5签名
  """
  def sign_md5(str),do: Base.encode16(:erlang.md5(str), case: :lower)

  @doc """
    发送get请求
  """
  @spec get_req(binary):: {true,map}|{false,binary | map}
  def get_req(url) do
    response = HTTPotion.get(url)
    {HTTPotion.Response.success?(response),Map.get(response,:body) || Map.get(response,:message)}
  end

end
