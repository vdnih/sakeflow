import { getCategory } from '@/libs/microcms';
import styles from './layout.module.css';

type Props = {
  children: React.ReactNode;
  params: {
    categoryId: string;
  };
};

export default async function CategoryLayout({ children, params }: Props) {
  const { categoryId } = params;
  const category = await getCategory(categoryId);
  return (
    <div>
      <p className={styles.title}>
        {category.name} の記事一覧
      </p>
      <div>{children}</div>
    </div>
  );
}
