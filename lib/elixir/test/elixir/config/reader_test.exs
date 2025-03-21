# SPDX-License-Identifier: Apache-2.0
# SPDX-FileCopyrightText: 2021 The Elixir Team
# SPDX-FileCopyrightText: 2012 Plataformatec

Code.require_file("../test_helper.exs", __DIR__)

defmodule Config.ReaderTest do
  use ExUnit.Case, async: true

  doctest Config.Reader
  import PathHelpers

  test "read_imports!/2" do
    assert Config.Reader.read_imports!(fixture_path("configs/good_kw.exs")) ==
             {[my_app: [key: :value]], [fixture_path("configs/good_kw.exs")]}

    assert Config.Reader.read_imports!(fixture_path("configs/good_config.exs")) ==
             {[my_app: [key: :value]], [fixture_path("configs/good_config.exs")]}

    assert Config.Reader.read_imports!(fixture_path("configs/good_import.exs")) ==
             {[my_app: [key: :value]],
              [fixture_path("configs/good_config.exs"), fixture_path("configs/good_import.exs")]}

    assert_raise ArgumentError,
                 ":imports must be a list of paths",
                 fn -> Config.Reader.read_imports!("config", imports: :disabled) end

    assert_raise File.Error,
                 fn -> Config.Reader.read_imports!(fixture_path("configs/bad_root.exs")) end

    assert_raise File.Error,
                 fn -> Config.Reader.read_imports!(fixture_path("configs/bad_import.exs")) end
  end

  test "read!/2" do
    assert Config.Reader.read!(fixture_path("configs/good_kw.exs")) ==
             [my_app: [key: :value]]

    assert Config.Reader.read!(fixture_path("configs/good_config.exs")) ==
             [my_app: [key: :value]]

    assert Config.Reader.read!(fixture_path("configs/good_import.exs")) ==
             [my_app: [key: :value]]

    assert Config.Reader.read!(fixture_path("configs/env.exs"), env: :dev, target: :host) ==
             [my_app: [env: :dev, target: :host]]

    assert Config.Reader.read!(fixture_path("configs/env.exs"), env: :prod, target: :embedded) ==
             [my_app: [env: :prod, target: :embedded]]

    assert_raise ArgumentError,
                 ~r"expected config for app :sample in .*/bad_app.exs to return keyword list",
                 fn -> Config.Reader.read!(fixture_path("configs/bad_app.exs")) end

    assert_raise RuntimeError, "no :env key was given to this configuration file", fn ->
      Config.Reader.read!(fixture_path("configs/env.exs"))
    end

    assert_raise RuntimeError, "no :target key was given to this configuration file", fn ->
      Config.Reader.read!(fixture_path("configs/env.exs"), env: :prod)
    end

    assert_raise RuntimeError,
                 ~r"import_config/1 is not enabled for this configuration file",
                 fn ->
                   Config.Reader.read!(fixture_path("configs/good_import.exs"),
                     imports: :disabled
                   )
                 end
  end

  test "eval!/3" do
    files = ["configs/good_kw.exs", "configs/good_config.exs", "configs/good_import.exs"]

    for file <- files do
      file = fixture_path(file)
      assert Config.Reader.read!(file) == Config.Reader.eval!(file, File.read!(file))
    end

    file = fixture_path("configs/env.exs")

    assert Config.Reader.read!(file, env: :dev, target: :host) ==
             Config.Reader.eval!(file, File.read!(file), env: :dev, target: :host)
  end

  test "as a provider" do
    state = Config.Reader.init(fixture_path("configs/good_config.exs"))
    assert Config.Reader.load([my_app: [key: :old_value]], state) == [my_app: [key: :value]]

    state = Config.Reader.init(path: fixture_path("configs/env.exs"), env: :prod, target: :host)

    assert Config.Reader.load([my_app: [env: :dev]], state) ==
             [my_app: [env: :prod, target: :host]]
  end
end
