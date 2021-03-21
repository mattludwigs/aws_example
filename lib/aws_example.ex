defmodule AwsExample do
  alias X509.Certificate

  def cert(_opts \\ []) do
    cert_path = Path.join(priv_dir(), "keys/certificate.pem.crt")

    case File.read(cert_path) do
      {:ok, cert_pem} ->
        Certificate.from_pem(cert_pem)

      error ->
        error
    end
  end

  def key(_opts \\ []) do
    key_path = Path.join(priv_dir(), "keys/private.pem.key")

    if File.exists?(key_path) do
      {:ok, key_path}
    else
      {:error, :missing_keyfile}
    end
  end

  def ca(_opts \\ []) do
    ca_path = Path.join(priv_dir(), "keys/AWSRootCA1.pem")

    case File.read(ca_path) do
      {:ok, ca_pem} ->
        Certificate.from_pem(ca_pem)

      error ->
        error
    end
  end

  def host(_opts \\ []) do
    host_file = Path.join(priv_dir(), "host")

    File.read!(host_file)
  end

  def connect() do
    with {:ok, cert} <- cert(),
         {:ok, key} <- key(),
         {:ok, ca} <- ca() do
      connect(host(), cert, key, ca)
    end
  end

  def connect(host, cert_path, key_path, ca_path) do
    server_opts = make_server_opts(host, cert_path, key_path, ca_path)

    opts = [
      handler: Jackalope.Handler.Logger,
      client_id: "elixir-test",
      server: server_opts
    ]

    Jackalope.start_link(opts)
  end

  def make_server_opts(host, cert, key, ca) do
    {
      Tortoise.Transport.SSL,
      [
        host: host,
        port: 8883,
        cert: Certificate.to_der(cert),
        keyfile: key,
        cacerts: [Certificate.to_der(cert), Certificate.to_der(ca)],
        partial_chain: &partial_chain/1,
        verify: :verify_peer,
        server_name_indication: '*.iot.us-east-1.amazonaws.com',
        versions: [:"tlsv1.2"]
        # logging_level: :debug
      ]
    }
  end

  defp partial_chain(server_certs) do
    aws_root_certs = [cert(), ca()] |> Enum.map(fn {:ok, i} -> i end)

    Enum.each(server_certs, fn cert_der ->
      nil
      # cert = Certificate.from_der!(cert_der)

      # IO.inspect("=====================")
      # IO.inspect("        ISSUER       ")
      # IO.inspect(Certificate.issuer(cert))
      # IO.inspect("=====================")
      # IO.inspect("       SUBJECT       ")
      # IO.inspect(Certificate.subject(cert))
      # IO.inspect("=====================")
    end)

    Enum.reduce_while(
      aws_root_certs,
      :unknown_ca,
      fn aws_root_ca, unk_ca ->
        certificate_subject = X509.Certificate.extension(aws_root_ca, :subject_key_identifier)

        case find_partial_chain(certificate_subject, server_certs) do
          {:trusted_ca, _} = result -> {:halt, result}
          :unknown_ca -> {:cont, unk_ca}
        end
      end
    )
  end

  defp find_partial_chain(_root_subject, []) do
    :unknown_ca
  end

  defp find_partial_chain(root_subject, [h | t]) do
    cert = X509.Certificate.from_der!(h)
    cert_subject = X509.Certificate.extension(cert, :subject_key_identifier)

    if cert_subject == root_subject do
      {:trusted_ca, h}
    else
      find_partial_chain(root_subject, t)
    end
  end

  defp priv_dir() do
    Application.app_dir(:aws_example, "priv")
  end
end
