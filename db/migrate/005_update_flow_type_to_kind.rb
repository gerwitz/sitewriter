Sequel.migration do
  up do
    add_column :flows, :post_kind, String, size: 255
    from(:flows).where(post_type_id: 1).update(post_kind: 'article')
    from(:flows).where(post_type_id: 2).update(post_kind: 'note')
    drop_column :flows, :post_type_id
  end

  down do
    add_column :flows, :post_type_id, Integer
    from(:flows).where(post_kind: 'article').update(post_type_id: 1)
    from(:flows).where(post_kind: 'note').update(post_type_id: 2)
    drop_column :flows, :post_kind
  end
end
