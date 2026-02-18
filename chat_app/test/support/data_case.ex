defmodule ChatApp.DataCase do
  use ExUnit.CaseTemplate

  using opts do
    quote do
      use ExUnit.Case, unquote(opts)

      alias ChatApp.Repo
      import Ecto
      import Ecto.Changeset
      import Ecto.Query
    end
  end

end
