type Category = {
  id: string;
  name: string;
};

type Props = {
  category: Category;
};

export default function CategoryListItem({ category }: Props) {
  return <span>{category.name}</span>;
}