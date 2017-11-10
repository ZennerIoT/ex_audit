defprotocol ExAudit.Tracker do
  @moduledoc """
  Enables you to influence which fields are tracked. In map_struct, remove or alter any fields
  you don't want tracked.

  Most of the time, you can just use 
  ```
  @derive {ExAudit.Tracker, options}
  ```

  where options is either: 

   * `except: [:foo, :bar]` to ignore certain fields or 
   * `only: [:baz, :foobar]` to track only those fields.
  """

  @fallback_to_any true

  def map_struct(struct)
end

defimpl ExAudit.Tracker, for: Any do
  @ignored_fields [:__meta__, :__struct__]

  defmacro __deriving__(module, struct, options) do
    deriving(module, struct, options)
  end

  def deriving(module, _struct, options) do
    only = options[:only]
    except = options[:except]

    extractor = cond do
      only ->
        quote(do: Map.take(struct, unquote(only)))
      except ->
        except = @ignored_fields ++ except
        quote(do: Map.drop(struct, unquote(except)))
      true ->
        quote(do: Map.drop(struct, unquote(@ignored_fields)))
    end

    quote do
      defimpl ExAudit.Tracker, for: unquote(module) do
        def map_struct(struct) do
          unquote(extractor)
        end
      end
    end
  end

  def map_struct(struct) do
    Map.drop(struct, @ignored_fields)
  end
end