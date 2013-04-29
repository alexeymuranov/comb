# encoding: UTF-8 (magic comment)

module NestedArrays
  module_function

    ##
    # Theses functions allows to "unfold" nested arrays as follows:
    #
    #   s_unfold [ :a,
    #              [ :b, [ 1,
    #                      2,
    #                      [3, :v0] ] ],
    #              [ :c, [ [4, :v1],
    #                      [5, :v2],
    #                      [6, [ :v3,
    #                            :v4 ] ] ] ] ]
    #   # => [ [:a],
    #   #      [:b, 1],
    #   #      [:b, 2],
    #   #      [:b, 3, :v0],
    #   #      [:c, 4, :v1],
    #   #      [:c, 5, :v2],
    #   #      [:c, 6, :v3],
    #   #      [:c, 6, :v4] ]
    #
    #   p_unfold [:a, [1, 2, 3], [:X, :Y], 0]
    #   # => [ [:a, 1, :X, 0],
    #   #      [:a, 1, :Y, 0],
    #   #      [:a, 2, :X, 0],
    #   #      [:a, 2, :Y, 0],
    #   #      [:a, 3, :X, 0],
    #   #      [:a, 3, :Y, 0] ]
    #
    #   s_unfold [[1, 2], []] # => [[1, 2], []]
    #   p_unfold [[1, 2], []] # => []
    #
    #   s_unfold [[1]] # => [[1]]
    #   p_unfold [[1]] # => [[1]]
    #
    #   s_unfold [1]   # => [[1]]
    #   p_unfold [1]   # => [[1]]
    #
    #   s_unfold [[]]  # => [[]]
    #   p_unfold [[]]  # => []
    #
    #   s_unfold []    # => []
    #   p_unfold []    # => [[]]
    #
    # These functions (are expected to) satisfy the following mathematical
    # relations:
    #
    # * s_unfold(s_unfold(x)) = s_unfold(x)
    #
    # * s_unfold(p_unfold(x)) = p_unfold(x)
    #
    # They can be used to submit an array of arrays of arguments in a more
    # concise form, for example:
    #
    #   def foo(*args)
    #     if args.first.is_a?(Array)
    #       args = s_unfold(args)
    #     else
    #       args = p_unfold(args)
    #     end
    #     # ...
    #   end
    #
    #   foo(:a, [1, 2, 3])
    #   # same effect as
    #   # foo([:a, 1], [:a, 2], [:a, 3])
    #
    #   foo([:a, [1, 2, 3]], [:b, [4, 5]], [:c, 6])
    #   # same effect as
    #   # foo([:a, 1], [:a, 2], [:a, 3], [:b, 4], [:b, 5], [:c, 6])
    #
    def s_unfold(arrays)
      arrays.reduce([]) { |memo, obj|
        memo.concat(obj.is_a?(Array) ? p_unfold(obj) : [[obj]])
      }
    end

    def p_unfold(arrays)
      arrays.reduce([[]]) { |memo, obj|
        memo.product(obj.is_a?(Array) ? s_unfold(obj) : [[obj]]).map(&:flatten)
      }
    end

end
